let url = "https://8she9oufme.execute-api.us-east-1.amazonaws.com/default" 

async function getResponse(uri) {
  try {
      let res = await fetch(url+uri);
      return await res.json();
  } catch (error) {
      console.log(error);
  }
}

async function renderResponse(uri) {
  let resp = await getResponse(uri);
  let html = '';
  console.log(resp);
  let htmlSegment = `<div class="user">
                      <h1>${resp}<h1>
                    </div>`;

  html += htmlSegment;

  let container = document.querySelector('.container');
  container.innerHTML = html;
}
