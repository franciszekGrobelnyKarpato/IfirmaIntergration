@isTest
public with sharing class hmacGeneratorTest {
    @isTest
    public static void givenBodyAndKeyThenGenerateHash(){
        String body  = 'https://www.ifirma.pl/iapi/fakturakraj/1_2020.jsonumsir@wp.plfaktura';
        String key = '5BC3A3E1F5382899';
        String hash = hmacGenerator.generateHmacSHA1(body, key);  
        System.assertEquals(hash,'c6bc221e65cceb7aab829fcfa9a89920520962f0');
    }
}