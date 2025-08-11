@RestResource(urlMapping='/servicerequest/*')
global with sharing class ServiceRequestRest {

    @HttpGet
    global static List<Service_Request__c> getRecord() {

        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        // Get the ID of the current user
        Id currentUserId = UserInfo.getUserId(); 
        
        // Query for the Group IDs that the current user is a member of.
        // The GroupMember.UserOrGroupId can be either a User ID or another Group ID.
        Set<Id> userGroupIds = new Set<Id>();
        for (GroupMember member : [SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :currentUserId]) {
            userGroupIds.add(member.GroupId);
        }

        List<Service_Request__c> serviceRequests = [SELECT Id, Name, Subject__c, Description__c, Status__c, CreatedDate
            FROM Service_Request__c
            WHERE OwnerId  = :currentUserId     OR    OwnerId IN :userGroupIds
            ORDER BY CreatedDate DESC];

        res.statusCode = 200;
        return serviceRequests;
    }

    @HttpPost
    global static Void createRecord() {
        
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            // Parse the request body to get the JSON data
            String requestBody = req.requestBody.toString();
            Map<String, Object> requestData = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

            String subject = (String)requestData.get('subject');
            String description = (String)requestData.get('description');
            String status = (String)requestData.get('status');
            
            Map<String, Object> responseMap = new Map<String, Object>();

            if (String.isBlank(subject) || String.isBlank(description)) {
                res.statusCode = 400; // Bad Request
                responseMap.put('status', 'error');
                responseMap.put('message', 'Error creating service request: Subject and Description are required fields.');
                res.responseBody = Blob.valueOf(JSON.serialize(responseMap));
            }

            // Create a new Service_Request__c record
            Service_Request__c newRequest = new Service_Request__c();
            newRequest.Subject__c = subject;
            newRequest.Description__c = description;
            if (String.isNotBlank(status)) {
                newRequest.Status__c = status;
            }
            insert newRequest;

            res.statusCode = 201; // Created
            responseMap.put('status', 'success');
            responseMap.put('message', 'Service Request created successfully.');
            responseMap.put('recordId', newRequest.Id);            
            res.responseBody = Blob.valueOf(JSON.serialize(responseMap));

        } catch (DMLException dml) {
            Map<String, Object> responseMap = new Map<String, Object>();
            responseMap.put('status', 'error');
            responseMap.put('message', 'Error creating service request: ' + dml.getDmlMessage(0));
            res.responseBody =  Blob.valueOf(JSON.serialize(responseMap));        
            // DML Exception (validation rule failure, required field missing, etc.)
            res.statusCode = 400;    
        } catch (Exception e) {
            Map<String, Object> responseMap = new Map<String, Object>();
            responseMap.put('status', 'error');
            responseMap.put('message', 'Error creating service request: ' + e.getMessage());
            res.responseBody = Blob.valueOf(JSON.serialize(responseMap));   
            // General Exception (unexpected error)
            res.statusCode = 500;
        }
    }
}