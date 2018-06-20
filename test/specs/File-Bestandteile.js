describe('Suche', function() {

    var assert = require('assert');
   
  it('bestimmte Seite aufrufen', function() {
  
  browser.url('http://localhost:8080/exist/apps/ssrq/SG/SSRQ_SG_III_4_10500712_1.xml?odd=ssrq.odd&view=body');                                            browser.pause(1000); 
      });
      
    it("Textabschnitt Regest öffnen", function() {
        var regest = browser.getText("a[href='#regest']");
        console.log('regest wurde gefunden: ', regest );        
        browser.click("a[href='#regest']");
        var regin = browser.getText('#regest p');
        console.log("der Text für regin ist =", regin);
        browser.isExisting("#regest p");
    });
     
    it("Textabschnitt Stückbeschreibung öffnen", function() { 
    browser.pause(1000); 
        browser.click('a[href="#sourceDesc"]');
        browser.isExisting("#sourceDesc");       
    });       
     
     it("Textabschnitt Weitere Überlieferungen öffnen", function() {
     browser.pause(2000); 
        browser.scroll("a[href='#additional']"); 
        browser.pause(2000); 
        browser.click("a[href='#additional']");
        browser.isExisting("#additional");
    });
        
     it("Textabschnitt Kommentar öffnen", function() {
     browser.pause(1000); 
        browser.scroll("a[href='#comment']");
        browser.click("a[href='#comment']");
        browser.isExisting("#comment");
       
        browser.pause(1000); 
        
        
    });
    
 });    