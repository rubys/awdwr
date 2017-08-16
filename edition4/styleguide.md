# Styleguide for Depot

## Font Scale

* Leave the Rails' default text size of 13px :(
* Sizes:
  - 3.998em
  - 2.827em
  - 1.999em
  - 1.414em
  - 1em
  - 0.707em
  - 0.5em
  - 0.354em
* No font, padding, margin, or other size should deviate from the above type scale
* If larger or smaller sizes are needed, multiple or divide by 1.414.
* Always use ems (so if/when Rails changes their default size, we are good.
* Don't restyle the scaffolding CSS unless we are in there.

## General

* Everything should work on mobile
* Use mobile-first, i.e. override things only for desktop
* Use 30em as the "assume it's desktop" width and omit screen so phantomjs works in PDF mode:

  ```
  @media (min-width: 30em) {
  }
  ```
* Use HTML5 elements properly
* Avoid ids for styling
