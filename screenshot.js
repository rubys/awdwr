#!/usr/bin/env node
'use strict';

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

// form_data is not supported yet

// if an exception is raised asynchronously, shut down
process.on('unhandledRejection', (reason, promise) => {
  console.log(reason.stack || reason);
  process.exit(1);
});

// convert page to PDF
puppeteer.launch().then(async browser => {
  const page = await browser.newPage();

  // fetch the page in question
  await page.goto(params.uri, {waitUntil: 'networkidle0'});

  // fill in forms
  if (params.form_data) {
    for (let [selector, text] of Object.entries(params.form_data)) {
      if (selector.match(/^#.*\]/)) {
       selector = selector.replace(/\[(\w+)\]$/, '_$1')
      }

      await page.type(selector, text);

    }
  }

  // optionally submit form
  if (params.submit_form) {
    if (typeof params.submit_form == "number") {
      let element = (await page.$$("*[type=submit]"))[params.submit_form];
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
  }

  // remove top margins from tailwindcss pages, extract main rectangle
  let rectangle = await page.$eval('main', main => {
    main.classList.remove("mt-28")
    return main.getClientRects()[0].toJSON()
  });

  // default height to size of main rectangle
  if (!params.dimensions) {
    params.dimensions = {
      height: Math.round(rectangle.height),
      width: 800
    };
  }

  // resize page
  await page.addStyleTag({
    content: '@page { size: auto; }',
  })

  await page.setViewport({
    ...params.dimensions,
    deviceScaleFactor: 3
  });

  // produce the PDF
  const pdf = await page.pdf({
    ...params.dimensions, 
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
  }

  // wait for completion
  await browser.close();
});
