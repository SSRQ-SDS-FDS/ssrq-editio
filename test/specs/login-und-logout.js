
describe('Login and out', function() {

    var assert = require('assert');

  it('start Seite aufrufen', function() {
  
  browser.url('http://localhost:8080/exist/apps/ssrq/')           
        
      });
      
    it("Login Daten eingeben", function() {
    
        browser.click("[href='#loginDialog']");
        browser.pause(1000);      
        browser.setValue('input[name="user"]', 'gsk');
        browser.setValue('input[name="password"]', 'gsk');  
        browser.click(".btn*=Login");
        
    });
    
    it("login erfolgreich prüfen", function() {
        
        var logout = browser.getText('#logout');
        console.log("der Text ist =", logout );
        assert(logout  === 'account_circle Logout gsk');
    
     });    
        
    it("Logout anklicken", function() {
    
       logout = "#logout";
        console.log("der Text ist =", logout );
        browser.click("#logout");
        browser.pause(1000);      
     
    });
    
    it("Logout erfolgreich prüfen", function() {
        var login = browser.getText("[href='#loginDialog']");
        console.log("der Text ist =", login );
        assert(login  === 'account_circle Login');
        
    });
    
});
