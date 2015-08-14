trigger StoreNumIssues on Scorecard__c (after insert, after update) {

    Set<Id> Campaigns = new Set<Id>();
        
    For (Scorecard__c sc: Trigger.New){
        Campaigns.add(sc.Rare_Campaign__c);
    }
    
    // Initialize a Map
  Map<Id, Integer> scIssues = New Map <Id, Integer>();
    
    // Query to get IDs for current Scorecard
  Rare_Campaign__c [] rc = [SELECT Id, Number_Compliance_Issues__c, (SELECT Id FROM Score_Cards__r WHERE Submission_Date__c != NULL ORDER BY Submission_Date__c DESC LIMIT 1) 
                                         FROM Rare_Campaign__c WHERE Id IN :Campaigns];
    
    // Initialize a list to hold current Scorecard IDs
    List<Id> currentScIds = New List<Id>();
    
    // Loop through result set and grab current Scorecard IDs, add to currentScIds
    For(Rare_Campaign__c rd : rc) {
      If (rd.Score_Cards__r.size() > 0) {
        currentScIds.add(rd.Score_Cards__r[0].id);
        } 
    }
    System.debug('>>>>> Scorecard IDs in currentScIds: ' + currentScIds);
    
    // Query to get # of issues for each Scorecard ID
  AggregateResult[] numIssues = [SELECT scorecard_answer__r.scorecard__r.rare_campaign__r.Id sccamp, count(question_choice__c) issueCount FROM question_choice_selection__c 
                                   WHERE scorecard_answer__r.questions__r.name = 'SC 13' AND scorecard_answer__r.scorecard__c IN :currentScIds 
                                   GROUP BY scorecard_answer__r.scorecard__r.rare_campaign__r.Id];
    System.debug('>>>>> Result for numIssues query: ' + numIssues);
    
    // Loop through results and add Scorecard ID, # of issues into Map
    For(AggregateResult issue: numIssues) {
        scIssues.put(string.valueOf(issue.get('sccamp')), (integer)issue.get('issueCount'));
        System.debug(string.valueOf(issue.get('sccamp')) + ' : ' + (integer)issue.get('issueCount'));
    }
  
  List<Rare_Campaign__c> updateRcList = new List<Rare_Campaign__c>();
    
    // Loop through Current results and pull value from Map, set value to NumIssues field on Rare_Campaigns__C
    For(Rare_Campaign__c newRd : rc){
        If(scIssues.containsKey(newRd.Id)){
            newRd.Number_Compliance_Issues__c = scIssues.get(newRd.Id);
            updateRcList.add(newRd);
        }
    }
    
    System.debug('>>>>> Results for updateRcList: ' + updateRcList);
  // Update Rare Campaign
  update updateRcList;
}
