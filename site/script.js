async function updateViewCount(apiEndpoint) {
  try {
    // fetch is used to sent a GET request to our api endpoint
    const response = await fetch(apiEndpoint, {
      method: 'GET',
      mode: 'cors'
    });
    // just some error handling incase we dont get a HTTP 200
    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }
    // Will read the body of our response in JSON
    const data = await response.json();
    const viewCountElement = document.getElementById('view-count');

    if (viewCountElement) {
      viewCountElement.innerText = data.views;
    } else {
      console.warn("Element with ID 'view-count' not found.");
    }

  } catch (error) {
    console.error('Failed to fetch view count:', error);
  }
}

// Will run automatically when the page loads and run our viewcount function
window.onload = () => {
  const apiEndpoint = 'APIENDPOINT/PROD/VIEWS';
  updateViewCount(apiEndpoint);
};