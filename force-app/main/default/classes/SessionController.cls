public with sharing class SessionController {
    /**
     * Returns the current user's session ID.
     * This method is used to retrieve the session ID for the current user.
     * 
     * @return String - The session ID of the current user.
     */
    @AuraEnabled(cacheable=false)
    public static String getSessionId() {
        return UserInfo.getSessionId();
    }
}