public with sharing class hmacGenerator {
    
    public static String generateHmacSHA1(String body, String key){        
        Blob hash = Crypto.generateMac('hmacSHA1', Blob.ValueOf(body), EncodingUtil.convertFromHex(key));        
        return EncodingUtil.convertToHex(hash);
    }
}