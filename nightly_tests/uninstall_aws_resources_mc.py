import os
import time
import boto3
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException

def setup_driver():
    options = Options()
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('window-size=1024x768')
    grid_url = 'http://localhost:4444/wd/hub'
    driver = webdriver.Remote(command_executor=grid_url, options=options)
    return driver


def get_ec2_instance_id():
    # Initialize a boto3 EC2 resource
    ec2 = boto3.resource('ec2')

    # The name of your instance
    instance_name = "Unity Management Console EC2 Instance"

    # Use filters to find instances by their Name tag
    instances = ec2.instances.filter(
        Filters=[{'Name': 'tag:Name', 'Values': [instance_name]}]
    )

    for instance in instances:
        # Assuming there's only one instance with this name
        return instance.id

    # Return None if no instance found
    return None


def wait_for_uninstall_complete(log_group_name, log_stream_name, completion_message, check_interval=10, timeout=600):
    cw_client = boto3.client('logs')
    start_time = time.time()
    
    while True:
        elapsed_time = time.time() - start_time
        if elapsed_time > timeout:
            print("Timeout waiting for uninstall to complete.")
            return False

        try:
            response = cw_client.get_log_events(
                logGroupName=log_group_name,
                logStreamName=log_stream_name,
                startFromHead=False
            )
            events = response.get('events', [])
            for event in events:
                if completion_message in event.get('message', ''):
                    print("Uninstall process completed successfully.")
                    return True
        except Exception as e:
            print(f"Error checking logs: {e}")
            return False

        time.sleep(check_interval)



def uninstall_aws_resources():
    # url = os.getenv('MANAGEMENT_CONSOLE_URL')
    url = 'HTTP://heaUyZ-unity-proxy-httpd-alb-955851503.us-west-2.elb.amazonaws.com:8080/management/ui'
    if not url:
        print("MANAGEMENT_CONSOLE_URL environment variable is not set.")
        return
    
    driver = setup_driver()
    try:
        driver.get(url)
        time.sleep(2)  # Wait for the page to load

        uninstall_link = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, "//a[contains(@class, 'inline-flex') and contains(text(), 'Uninstall')]"))
        )
        driver.execute_script("arguments[0].click();", uninstall_link)
        time.sleep(2)  # Adjust this delay as necessary

        go_button = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, "//button[contains(text(), 'Go!')]"))
        )
        driver.execute_script("arguments[0].click();", go_button)
        print("Uninstall process initiated successfully.")

    except TimeoutException:
        print("Failed to perform uninstall - either elements were not clickable or not found as expected.")
    finally:
        driver.quit()  # Quit the driver as soon as the web interactions are done

    # Retrieve the EC2 instance ID after quitting the driver
    instance_id = get_ec2_instance_id()
    print(instance_id)
    # Assuming the log stream name follows a specific pattern with the instance ID
    log_stream_name = instance_id  # Adjust if your log stream naming convention differs
    # Call the function to monitor CloudWatch logs after the driver has been quit
    wait_for_uninstall_complete("managementconsole", log_stream_name, "UNITY MANAGEMENT CONSOLE UNINSTALL COMPLETE")



if __name__ == "__main__":
    uninstall_aws_resources()

