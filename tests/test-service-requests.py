import pytest
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException

# --- Configuration (Update these values) ---
SALESFORCE_SITE_URL = "https://login.salesforce.com/"
SALESFORCE_USERNAME = "aniltilanthe92@playful-narwhal-2dym8q.com"
SALESFORCE_PASSWORD = "Anil@1234"

# --- Locators (Update these with your application's specific locators) ---
LOCATOR_USERNAME_INPUT = (By.ID, "username")
LOCATOR_PASSWORD_INPUT = (By.ID, "password")
LOCATOR_LOGIN_BUTTON = (By.NAME, "Login")
# A locator for a page element that appears after successful login.
# Replace this with a unique ID, class, or other selector for your authenticated page.
LOCATOR_AUTH_PAGE_ELEMENT = (By.XPATH, "//div[contains(@class, 'slds-page-header')]")
# New locator for the App Launcher button, which is the grid of nine dots.
LOCATOR_APP_LAUNCHER = (By.XPATH, "//button[contains(@class, 'slds-context-bar__button')]")
# Locator for the navigation link to the Service Requests page.
# You will need to inspect your site's navigation menu to find this.
LOCATOR_RECORDS_PAGE_LINK = (By.XPATH, "//a[@title='Service']")
# Locator for the list of service request records.
# This should point to the container of the records.
LOCATOR_SERVICE_REQUESTS_LIST = (By.XPATH, "//div[contains(@class, 'service-request-list-container')]")
# Locator for an individual record within the list.
# This should point to a repeating element like a list item or a row.
LOCATOR_SINGLE_SERVICE_REQUEST_RECORD = (By.XPATH, ".//li[contains(@class, 'service-request-item')]")

# --- Fixture for WebDriver setup and teardown ---
@pytest.fixture(scope="module")
def driver():
    """
    Sets up a Chrome WebDriver instance and ensures it's closed after all tests
    in the module are complete.
    """
    options = webdriver.ChromeOptions()
    # Uncomment the line below to run the test in headless mode (no browser window).
    # options.add_argument("--headless")
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.add_argument("--window-size=1920,1080")
    
    # Initialize the WebDriver
    _driver = webdriver.Chrome(options=options)
    _driver.maximize_window()
    _driver.implicitly_wait(10) # Set a global implicit wait time
    
    yield _driver
    
    # Teardown: close the browser after the test
    _driver.quit()

# --- The Test Case ---
def test_service_request_records_display(driver):
    """
    Tests that a list of service request records is correctly displayed
    on a Salesforce Experience Cloud page.
    """
    try:
        print("\n--- Starting Salesforce Experience Cloud Test ---")
        
        # 1. Navigate to the Salesforce site
        print("Navigating to the Salesforce Experience Cloud site...")
        driver.get(SALESFORCE_SITE_URL)
        
        # 2. Login
        print("Attempting to log in...")
        WebDriverWait(driver, 20).until(
            EC.presence_of_element_located(LOCATOR_USERNAME_INPUT)
        ).send_keys(SALESFORCE_USERNAME)
        
        driver.find_element(*LOCATOR_PASSWORD_INPUT).send_keys(SALESFORCE_PASSWORD)
        driver.find_element(*LOCATOR_LOGIN_BUTTON).click()
        
        # Wait for the authenticated page to load
        WebDriverWait(driver, 30).until(
            EC.presence_of_element_located(LOCATOR_AUTH_PAGE_ELEMENT)
        )
        print("Successfully logged in.")

        # 3. Open the App Launcher (the grid of nine dots)
        print("Opening the App Launcher...")
        WebDriverWait(driver, 20).until(
            EC.element_to_be_clickable(LOCATOR_APP_LAUNCHER)
        ).click()
        
        # 4. Navigate to the Service Requests page
        print("Navigating to the Service Request records page...")
        WebDriverWait(driver, 20).until(
            EC.element_to_be_clickable(LOCATOR_RECORDS_PAGE_LINK)
        ).click()
        
        # 3. Locate the list of service requests
        print("Locating the service request list...")
        service_request_list_container = WebDriverWait(driver, 30).until(
            EC.presence_of_element_located(LOCATOR_SERVICE_REQUESTS_LIST)
        )
        print("Service request list container found.")
        
        # 4. Find all individual records within the list
        service_request_records = service_request_list_container.find_elements(
            *LOCATOR_SINGLE_SERVICE_REQUEST_RECORD
        )
        
        # 5. Assert that at least one record is displayed
        assert len(service_request_records) > 0, (
            "No service request records were found in the list. "
            "Please check the locator and data."
        )
        
        print(f"Test Passed: Found {len(service_request_records)} service request records.")
        
    except (TimeoutException, NoSuchElementException) as e:
        print(f"\nTest Failed: A critical element could not be found.")
        print(f"Error: {e}")
        pytest.fail(f"Test failed due to an element not being found or a timeout: {e}")
