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

// form_data is not supported yet
if (params.form_data) process.exit(0);

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

  // produce the PDF
  const pdf = await page.pdf({ ...params.dimensions, pageRanges: '1'});

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
