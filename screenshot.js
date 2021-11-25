#!/usr/bin/env node
'use strict';
const child_process = require('child_process')

let scale = 2;

//
// Use puppeteer to convert a web page to PDF.
//

const path = require('path');
const puppeteer = require(path.resolve(__dirname, 'node_modules/puppeteer'));
const fs = require('fs');

// extract instructions from the argument passed
const params = JSON.parse(process.argv[2]);
let date = new Date();
console.error(`[${date.toLocaleString('sv')}] SNAP  ${params.filename}`);

// if an exception is raised asynchronously, shut down
process.on('unhandledRejection', (reason, promise) => {
  console.log(reason.stack || reason);
  process.exit(1);
});

// convert page to PDF
puppeteer.launch().then(async browser => {
  const page = await browser.newPage();
  let output = {};

  // add cookies
  if (params.cookies) {
    await page.setCookie(...params.cookies);
  }

  // fetch the page in question
  await page.goto(params.uri, {waitUntil: 'networkidle2'});

  // fill in forms
  if (params.form_data) {
    for (let [selector, text] of Object.entries(params.form_data)) {
      if (selector == "#_method") continue;

      if (selector.match(/^#.*\]/)) {
       selector = selector.replace(/\[(\w+)\]$/, '_$1')
      }

      await page.type(selector, text);
    }
  }

  // optionally submit form
  if (params.submit_form) {
    page.on('response', response => {
      if (!output.code || output.code >= 300) {
        output.code = response.status().toString();
        output.headers = response.headers();
      }
    });

    let forms = params.submit_form;
    if (!Array.isArray(forms)) forms = [forms];

    for (let index in forms) {
      let form = forms[index];

      if (typeof form == "number") {
	let element = (await page.$$("*[type=submit]"))[form-1];
	await Promise.all([
	  page.waitForResponse(response => response.status() === 200),
	  element.click()
	]);
      } else {
	await Promise.all([
	  // page.waitForNavigation({ waitUntil: 'networkidle0' }),
	  page.waitForResponse(response => response.status() === 200),
	  page.click("*[type=submit]")
	]);
     }

     if (index + 1 != forms.length) {
       await new Promise(r => setTimeout(r, 300));
     }
   };

  }

  // remove top margins from tailwindcss pages, extract main rectangle
  let rectangle = await page.evaluate(() => {
    let main = document.querySelector('main');
    if (main) {
      main.classList.remove("mt-28");
      return main.getClientRects()[0].toJSON();
    } else {
      return {height: window.innerHeight, width: window.innerWidth};
    }
  });

  // default height to size of main rectangle
  if (params.dimensions) {
    if (params.dimensions.height) params.dimensions.height *= scale;
    if (params.dimensions.width) params.dimensions.width *= scale;
  } else {
    params.dimensions = {
      height: Math.round(rectangle.height) * scale,
      width: 800 * scale
    };
  }

  // resize page
  await page.addStyleTag({
    content: '@page { size: auto; }',
  })

  await page.setViewport({
    ...params.dimensions,
    deviceScaleFactor: scale
  });

  // produce the PDF
  const pdf = await page.pdf({
    ...params.dimensions, 
    scale,
    printBackground: true,
    pageRanges: '1'
  });

  // replace the content of the output file if anything changes EXCEPT
  // for PDF date metadata.
  const dest = path.join(params.output_dir, params.filename);
  const before = fs.existsSync(dest) ?  fs.readFileSync(dest, 'utf8') : '';
  const strip = /^\/\w+Date \(D:[-+\d']+\)/gm
  if (before.replace(strip, '') !== pdf.toString().replace(strip, '')) {
    fs.writeFileSync(dest, pdf, 'utf8');

    // produce png
    if (dest.endsWith('.pdf')) {
      child_process.spawn('convert', ['-units', 'PixelsPerInch', dest,
        '-density', '300', '-quality', '90', '-colorspace', 'RGB',
        dest.replace('.pdf', '.png')], {detached: true})
    }
  }

  if (output.code) {
    output.url = page.url();
    output.body = await page.content();
    output.cookies = await page.cookies();

    console.log(JSON.stringify(output));
  }

  // wait for completion
  await browser.close();
});
