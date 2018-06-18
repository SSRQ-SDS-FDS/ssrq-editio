describe('Menüleiste checken', function() {

    var assert = require('assert');

  it('start Seite aufrufen', function() {
  
  browser.url('http://localhost:8080/exist/apps/ssrq/');         browser.pause(1000); 
        
      });
      
    it("Abkürzungen aufrufen", function() {
    
        browser.click('#abbr a');
        browser.pause(3000); 
        var abbr = browser.getText('#abbr a');
        console.log("der Text für aabr ist =", abbr);
        assert(abbr === 'Abkürzungen');
        browser.pause(3000); 
        
    });
    
    it("zurück zur Startseite", function() {
        
        var start = browser.getText('#about');
        console.log("der Text für Start ist =", start );
        assert(start  === 'Start');
        browser.click("#about");
         browser.pause(3000); 
    
     });   
      
     it("Sprache fr", function() {
        
       
        browser.click("//*[@id='lang-select']/option[2]");
        browser.pause(3000); 
        var franz = browser.getText('.page-header');
        console.log("der Text für franz ist =", franz );
        assert(franz  === 'Collection des sources du droit suisse online');
         browser.pause(3000); 
    
     }); 
     
     it("Sprache de", function() {
        
       
        browser.click("//*[@id='lang-select']/option[1]");
        browser.pause(3000); 
        var de = browser.getText('.page-header');
        console.log("der Text für de ist =", de );
        assert(de  === "Sammlung Schweizerischer Rechtsquellen online");
         browser.pause(3000); 
    
     });   
   
    
});
