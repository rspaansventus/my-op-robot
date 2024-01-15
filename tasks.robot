*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Desktop
Library             RPA.Excel.Files
Library             RPA.PDF
Library             RPA.Archive
Library             OperatingSystem


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Cleanup images and orders
    Open the robot order website
    Download the orders file
    Read csv file to table
    Select form 'Order your robot!'
    Fill the form
    Create ZIP package from PDF files


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com

Download the orders file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Read csv file to table
    ${orders}=    Read table from CSV    orders.csv
    FOR    ${order}    IN    @{orders}
        Log    ${order}
    END

Select form 'Order your robot!'
    Click Element    xpath://a[contains(@href,'robot-order')]
    Click Element    xpath://button[contains(@class,'btn-dark')]
    Does Page Contain Button    Preview
    Does Page Contain Button    Order

Fill and submit the form for one order
    [Arguments]    ${order}
    Select From List By Index    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://input[contains(@placeholder,'Enter the part number for the legs')]    ${order}[Legs]
    Input Text    xpath://input[contains(@placeholder,'Shipping address')]    ${order}[Address]

Fill the form
    ${orders}=    Read table from CSV    orders.csv    headers=True
    FOR    ${order}    IN    @{orders}
        Fill and submit the form for one order    ${order}
        Preview the robot
        Wait Until Keyword Succeeds    5x    3 sec    Submit the order
        Embed the order receipt and the robot screenshot to the PDF file    ${order}
        Order another robot
        Click Element    xpath://button[contains(@class,'btn-dark')]
    END

Preview the robot
    # [Arguments]    ${order}
    Click Element When Clickable    xpath://button[@id='preview' and @type='submit']
    # Take a screenshot of the robot image ${order}

Submit the order
    Click Element When Clickable    xpath://button[@id='order' and @type='submit']
    Page Should Contain Button    Order another robot

Order another robot
    Does Page Contain Button    Order another robot
    Click Element When Clickable    xpath://button[@id='order-another' and @type='submit']

Store the order receipt
    [Arguments]    ${order}
    Wait Until Element Is Visible    id:order-completion
    ${order_receipt_html}=    Get Element Attribute    xpath://div[@class='alert alert-success']    innerHTML
    Html To Pdf
    ...    ${order_receipt_html}
    ...    ${OUTPUT_DIR}${/}orders${/}order_receipt_${order["Order number"]}.pdf
    ...    overwrite=False

Take a screenshot of the robot image
    [Arguments]    ${order}
    Capture Element Screenshot
    ...    xpath://div[@id="robot-preview-image"]
    ...    ${OUTPUT_DIR}${/}order_image${/}robot_image_${order["Order number"]}.png

Embed the order receipt and the robot screenshot to the PDF file
    [Arguments]    ${order}
    Store the order receipt    ${order}
    Take a screenshot of the robot image    ${order}
    ${orders}=    Create List
    ...    ${OUTPUT_DIR}${/}orders${/}order_receipt_${order["Order number"]}.pdf
    ...    ${OUTPUT_DIR}${/}order_image${/}robot_image_${order["Order number"]}.png
    Add Files To Pdf
    ...    ${orders}
    ...    ${OUTPUT_DIR}${/}order_receipts${/}merged_order_receipt_${order["Order number"]}.pdf
    ...    overwrite=False

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}order_receipts
    ...    ${zip_file_name}

Cleanup images and orders
    Remove File    ${OUTPUT_DIR}${/}order_image${/}robot_image_*
    Remove File    ${OUTPUT_DIR}${/}orders${/}order_receipt_*
    Remove File    ${OUTPUT_DIR}${/}order_receipts${/}merged_order_receipt_*
