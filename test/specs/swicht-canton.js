describe('Kantone wechseln', function() {

    var assert = require('assert');
   
  it('start Seite aufrufen', function() {
  
  browser.url('http://localhost:8080/exist/apps/ssrq/');                            browser.pause(1000); 
        
      });
      
    it("von Kanton SG nach NE", function() {
     
        browser.click('[href*= "?kanton=NE"]');
        browser.pause(3000); 
        var cantonNE = browser.getText('li.document:first-child h5');
        console.log("der Text für cantonNE ist =", cantonNE );
        assert(cantonNE.value = "XXIe" );
        browser.pause(3000); 
        
    });
     
 });    
 
 