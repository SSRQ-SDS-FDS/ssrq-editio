describe('Suche', function() {

    var assert = require('assert');
   
  it('Startseite aufrufen', function() {
  
  browser.url('http://localhost:8080/exist/apps/ssrq/');                            browser.pause(1000); 
        
      });
      
    it("nur in Titel", function() {
     
        browser.click('label*=Regest');
        browser.click('label*=Kommentar');
        browser.click('label*=Anmerkung');
        browser.click('label*=Siegel');
        browser.pause(3000); 
        browser.setValue('input[name="query"]', '"Sax-Forstegg"');
        browser.click('#f-btn-search');
        browser.click('h4*=Sax-Forstegg');
        browser.pause(3000); 
        
    });
    
 });    