*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

# Library    Browser    auto_closing_level=MANUAL
# Library    RPA.Browser.Playwright
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.FileSystem
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             Screenshot
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault
Library             RPA.RobotLogListener


*** Variables ***
${orders_url}           https://robotsparebinindustries.com/#/robot-order
${file_url}             https://robotsparebinindustries.com/orders.csv
# ${download_path}    ${OUTPUT_DIR}${/}downloads
# ${file_path}    ${OUTPUT_DIR}${/}downloads${/}orders.csv
# ${receipts_path}    ${OUTPUT_DIR}${/}receipts
# ${screenshot_path}    ${OUTPUT_DIR}${/}screenshots
${download_path}        ${OUTPUT_DIR}
${file_path}            ${OUTPUT_DIR}${/}orders.csv
${receipts_path}        ${OUTPUT_DIR}
${screenshot_path}      ${OUTPUT_DIR}
${retry_max}            3x
${retry_interval}       1s
${retry_timeout}        1 min


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${orders_url}=    Wait Until Keyword Succeeds    ${retry_max}    ${retry_interval}    Ask user inputs
    Wait Until Keyword Succeeds    ${retry_max}    ${retry_interval}    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Wait Until Keyword Succeeds    ${retry_max}    ${retry_interval}    Close the annoying modal
        Wait Until Keyword Succeeds    ${retry_max}    ${retry_interval}    Fill the form    ${row}
        Wait Until Keyword Succeeds    ${retry_max}    ${retry_interval}    Preview the robot
        Wait Until Keyword Succeeds    ${retry_max}    ${retry_interval}    Submit the order
        ${pdf}=    Wait Until Keyword Succeeds
        ...    ${retry_max}
        ...    ${retry_interval}
        ...    Store the receipt as a PDF file
        ...    ${row}[Order number]
        ${screenshot}=    Wait Until Keyword Succeeds
        ...    ${retry_max}
        ...    ${retry_interval}
        ...    Take a screenshot of the robot
        ...    ${row}[Order number]
        Wait Until Keyword Succeeds
        ...    ${retry_max}
        ...    ${retry_interval}
        ...    Embed the robot screenshot to the receipt PDF file
        ...    ${screenshot}
        ...    ${pdf}
        Wait Until Keyword Succeeds    ${retry_max}    ${retry_interval}    Go to order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
Ask user inputs
    Add text input    url    label=Input URL    placeholder=Enter Orders URL here
    # Add text input    csv_path    label=CSV File Path    placeholder=Enter CSV file path here
    # Show dialog    User Inputs    800    800    True    True    False
    ${user_inputs}=    Run dialog
    RETURN    ${user_inputs.url}

Open the robot order website
    # RPA.Browser.Playwright.New Browser    chromium    headless=false
    # RPA.Browser.Playwright.New Context    viewport={'width':1920, 'height':1080}
    # RPA.Browser.Playwright.New Page    ${orders_url}
    RPA.Browser.Selenium.Open Available Browser    ${orders_url}    maximized=True
    # ...    ${orders_url}
    # ...    use_profile=False
    # ...    headless=false
    # ...    maximized=True
    # ...    browser_selection=firefox
    # ...    download=False
    # Open User Browser    ${orders_url}
    # Open Browser    ${orders_url}    firefox

Get Orders
    RPA.HTTP.Download    ${file_url}    target_file=${download_path}    overwrite=True
    ${table}=    Read table from CSV    ${file_path}
    Log    Found columns: ${table.columns}
    FOR    ${order}    IN    @{table}
        Log    ${order}
    END
    RETURN    ${table}

Close the annoying modal
    # Mute Run On Failure    Click Element If Visible    css:.btn.btn-dark
    Click Element If Visible    css:.btn.btn-dark

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text When Element Is Visible    css:.form-control    ${row}[Legs]
    Input Text When Element Is Visible    address    ${row}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Click Button    order

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${file_found}=    Does File Exist    ${receipts_path}${/}${order_number}.pdf
    IF    ${file_found} == ${True}
        Remove File    ${receipts_path}${/}${order_number}.pdf
    END
    ${alert_found}=    Does Page Contain Element    css:.alert.alert-danger
    WHILE    ${alert_found} == ${True}
        Submit the order
    END
    Wait Until Element Is Visible
    ...    id:receipt
    ...    timeout=${retry_timeout}
    ...    error=Receipt data either not loaded or order not submitted correctly
    ${receipt_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_results_html}    ${receipts_path}${/}${order_number}.pdf
    RETURN    ${receipts_path}${/}${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${file_found}=    Does File Exist    ${screenshot_path}${/}${order_number}.jpg
    IF    ${file_found} == ${True}
        Remove File    ${screenshot_path}${/}${order_number}.jpg
    END
    Take Screenshot Without Embedding    ${screenshot_path}${/}${order_number}.jpg
    RETURN    ${screenshot_path}${/}${order_number}.jpg

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Close All Pdfs
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close All Pdfs

Go to order another robot
    Click Element If Visible    order-another

Create a ZIP file of the receipts
    Close Browser
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip    ${receipts_path}    ${zip_file_name}
