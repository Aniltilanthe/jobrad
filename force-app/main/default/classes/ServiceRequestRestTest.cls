// ServiceRequestRestTest.cls
@IsTest
private class ServiceRequestRestTest {

    Static string testUserAlias = 'testuser';

    // Prepare test data
    @TestSetup
    static void setupTestData() {
        User testUser = createTestUser('Test User', 'test.user@jobrad.com');
        insert testUser;

        System.runAs(testUser) {
            // Create Service Requests for the test user
            List<Service_Request__c> requests = new List<Service_Request__c>();
            requests.add(new Service_Request__c(Subject__c = 'Test Request 1', Description__c = 'Description for test request 1', Status__c = 'New'));
            requests.add(new Service_Request__c(Subject__c = 'Test Request 2', Description__c = 'Description for test request 2', Status__c = 'In Progress'));
            requests.add(new Service_Request__c(Subject__c = 'Test Request 3', Description__c = 'Description for test request 3', Status__c = 'Closed'));
            insert requests;
        }
    }

    
    /**
     * @description Tests the GET method of the REST API.
     * Only the service requests of the logged-in user are returned.
     */
    @IsTest
    static void testGetServiceRequests() {
        User testUser = [SELECT Id FROM User WHERE Alias = :testUserAlias LIMIT 1];

        System.runAs(testUser) {
            // Mock REST request
            RestRequest request = new RestRequest();
            request.requestUri = '/services/apexrest/servicerequest';
            request.httpMethod = 'GET';
            RestContext.request = request;

            RestResponse response = new RestResponse();
            RestContext.response = response;

            // Call the method
            List<Service_Request__c> requests = ServiceRequestRest.getRecord();

            // Assertions
            System.assertNotEquals(null, requests, 'Requests should not be null.');
            System.assertEquals(3, requests.size(), 'Expected 3 service requests to be returned.');
            System.assertEquals(200, RestContext.response.statusCode, 'Status Code should be 200.');
        }
    }

    /**
     * @description Tests the POST method of the REST API for creating a service request.
     */
    @IsTest
    static void testCreateServiceRequest() {
        User testUser = [SELECT Id FROM User WHERE Alias = :testUserAlias LIMIT 1];

        System.runAs(testUser) {
            // Mock REST request
            RestRequest request = new RestRequest();
            request.requestUri = '/services/apexrest/servicerequest';
            request.httpMethod = 'POST';
            request.requestBody = Blob.valueOf('{"subject": "New Test Request at JobRad", "description": "This is a new service request."}');
            RestContext.request = request;

            RestResponse response = new RestResponse();
            RestContext.response = response;

            Test.startTest();
            ServiceRequestRest.createRecord();
            Test.stopTest();

            Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(RestContext.response.responseBody.toString());

            // Assertions
            System.assertNotEquals(null, resultMap, 'result should not be null.');
            System.assertEquals('success', resultMap.get('status'), 'Status should be "success".');
            System.assertEquals(201, RestContext.response.statusCode, 'Status Code should be 201.');

            List<Service_Request__c> createdRequests = [SELECT Id FROM Service_Request__c WHERE Subject__c = 'New Test Request at JobRad'];
            System.assertEquals(1, createdRequests.size(),  'A new service request should have been created in database with the subject.');
        }
    }

    /**
     * @description Tests the POST method with missing fields.
     */
    @IsTest
    static void testCreateServiceRequest_MissingFields() {
        User testUser = [SELECT Id FROM User WHERE Alias = :testUserAlias LIMIT 1];


        System.runAs(testUser) {
            RestRequest request = new RestRequest();
            request.requestUri = '/services/apexrest/servicerequest';
            request.httpMethod = 'POST';
            request.requestBody = Blob.valueOf('{"subject": "", "description": "Missing subject"}');
            RestContext.request = request;

            RestResponse response = new RestResponse();
            RestContext.response = response;

            Test.startTest();
            ServiceRequestRest.createRecord();
            Test.stopTest();

            Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(RestContext.response.responseBody.toString());

            System.debug(String.valueOf(resultMap.get('message')));
            system.debug(resultMap);
            System.assert(String.valueOf(resultMap.get('message')).contains('Subject') || String.valueOf(resultMap.get('message')).contains('Description'), 'Error message should indicate empty fields.');
        }
    }

    /**
     * @description method to create a test user.
     * @param userName The name of the user.
     * @param email The email address of the user.
     * @return User The created test user.
     */
    private static User createTestUser(String userName, String email) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1]; // Or a specific Community Profile
        return new User(
            Alias = testUserAlias,
            Email = email,
            EmailEncodingKey = 'UTF-8',
            LastName = userName,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'GMT',
            UserName = 'unique.testuser.' + System.currentTimeMillis() + '@jobrad.com' // Unique username
        );
    }
}