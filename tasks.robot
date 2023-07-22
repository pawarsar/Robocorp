*** Settings ***
Documentation      Orders robots from RobotSpareBin Industries Inc.
...                Saves the order HTML receipt as a PDF file.
...                Saves the screenshot of the ordered robot.
...                Embeds the screenshot of the robot to the PDF receipt.
...                Creates ZIP archive of the receipts and the images.

Library            RPA.Browser.Selenium    auto_close=${FALSE}
Library            RPA.Excel.Files
Library            RPA.Tables
Library            RPA.HTTP
Library            Dialogs
Library            RPA.PDF
Library            RPA.Desktop
Library            RPA.FileSystem
Library            OperatingSystem
Library            RPA.Salesforce
Library            RPA.Archive


*** Variables ***
${orders_file}    ${CURDIR}${/}orders.csv
${img_folder}     ${CURDIR}${/}image_files
${pdf_folder}     ${CURDIR}${/}pdf_files
${output_folder}  ${CURDIR}${/}output



*** Tasks ***
Download the CSV File
    Download    https://robotsparebinindustries.com/orders.csv    target_file=${orders_file}    overwrite=True    
    
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Wait Until Page Contains Element    class:alert-buttons
    Click Button    OK


    # Fill and submit the data
Fill the form using the data from csv file
    Set Local Variable    ${input_head}    //*[@id='head']
    Set Local Variable    ${input_body}    body
    Set Local Variable    ${input_legs}    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Set Local Variable    ${input_address}    //*[@id='address']
    Set Local Variable    ${btn_preview}      //*[@id="preview"]
    Set Local Variable    ${btn_order}        //*[@id="order"]
    Set Local Variable    ${img_preview}      //*


    ${orders}=    Read table from CSV    ${orders_file}    header=True

    FOR    ${order}    IN    @{orders}
        # Fill the order    ${order_row}
        Wait Until Page Contains Element    ${input_head}
        Wait Until Element Is Enabled    ${input_head}
        Select From List By Value    ${input_head}    ${order}[Head]

        Wait Until Element Is Enabled   ${input_body}
        Select Radio Button    ${input_body}    ${order}[Body]

        Wait Until Element Is Enabled   ${input_legs}
        Input Text    ${input_legs}    ${order}[Legs]

        Wait Until Element Is Enabled    ${input_address}
        Input Text    address    ${order}[Address]

        Preview the robot

        Wait Until Keyword Succeeds    2min    500ms    Submit the order
    
        ${order_id}    ${img_filename}=    Screenshot of the robot

        ${pdf_filename}=    Store the receipt as PDF file    Order_Number=${order_id}

        Embed the robot screenshot to the receipt PDF file     IMG_FILE=${img_filename}    PDF_FILE=${pdf_filename}


        Wait Until Element Is Visible    order-another
        Click Button            //*[@id="order-another"]

        Click pop-up OK Button
    END

    Create a ZIP file of the receipts
    Log Out And Close The Browser
    
    
*** Keywords ***

Click pop-up OK Button
    Click Button    OK

Preview the robot
    Set Local Variable              ${btn_preview}      //*[@id="preview"]
    Set Local Variable              ${img_preview}      //*[@id="robot-preview-image"]

    Click Button                    ${btn_preview}
    Wait Until Page Contains Element   ${img_preview}

Submit the order
    Set Local Variable              ${btn_order}        //*[@id="order"]
    Set Local Variable              ${lbl_receipt}      //*[@id="receipt"]

    Click button                    ${btn_order}
    Page Should Contain Element     ${lbl_receipt}


Screenshot of the robot
    Set Local Variable      ${lbl_orderid}      xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Set Local Variable    ${img_robot}    //*[@id="robot-preview-image"]

    Wait Until Element Is Visible   ${img_robot}
    Wait Until Element Is Visible   ${lbl_orderid}

    # get order ID
    ${orderid}=    Get Text    //*[@id="receipt"]/p[1]

    # Create the File Name
    Set Local Variable              ${fully_qualified_img_filename}    ${img_folder}${/}${orderid}.png
    Sleep   1sec

    Capture Element Screenshot      ${img_robot}    ${fully_qualified_img_filename}

    [Return]    ${orderid}  ${fully_qualified_img_filename}

Store the receipt as PDF file
    [Arguments]    ${Order_Number}

    Wait Until Element Is Visible   //*[@id="receipt"]

    ${order_receipt_html}=          Get Element Attribute   //*[@id="receipt"]  outerHTML

    Set Local Variable              ${fully_qualified_pdf_filename}    ${pdf_folder}${/}${ORDER_NUMBER}.pdf

    Html To Pdf                     content=${order_receipt_html}   output_path=${fully_qualified_pdf_filename}

    [Return]    ${fully_qualified_pdf_filename}


Embed the robot screenshot to the receipt PDF file

    [Arguments]     ${IMG_FILE}     ${PDF_FILE}
    Log To Console                  Printing Embedding image ${IMG_FILE} in pdf file ${PDF_FILE}
    Open PDF        ${PDF_FILE}
    # Create the list of files that is to be added to the PDF (here, it is just one file)

    @{myfiles}=       Create List     ${IMG_FILE}:x=0,y=0
    Add Files To PDF    ${myfiles}    ${PDF_FILE}    ${True}
    Close PDF           ${PDF_FILE}

Create a ZIP file of the receipts
    Archive Folder With Zip     ${pdf_folder}  ${output_folder}${/}pdf_archive.zip   recursive=True  include=*.pdf

Log Out And Close The Browser
    Close Browser
