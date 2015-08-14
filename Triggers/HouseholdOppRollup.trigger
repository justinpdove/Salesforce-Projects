trigger HouseholdOppRollup on Opportunity (after insert, after update, before delete) {
  
    Set<Id> HouseholdIds = new Set<Id>();
    List<Account> updateHouseholds = new List<Account>();
    List<Opportunity> updatedOpps = new List<Opportunity>();
    
    if(Trigger.isDelete){
        For(Opportunity opp : Trigger.old){
            updatedOpps.add(opp);
        }
  } 
    if(Trigger.isUpdate || Trigger.isInsert){
        For(Opportunity opp : Trigger.new){
            updatedOpps.add(opp);
        }
  }
    
    // Add AccountIds for new/updated opportunities into Households
    For(Opportunity opp : updatedOpps){
        HouseholdIds.add(opp.AccountId);
    }
    
    // Get AccountId and rollup info and store in AggregateResult object
    AggregateResult[] rollupResults = [SELECT AccountId, MAX(CloseDate) LastGift, MIN(CloseDate) FirstGift, SUM(Amount) TotalAmount,
                                       COUNT(Id) NumGifts, MAX(Amount) LargestGift FROM Opportunity WHERE AccountId IN :HouseholdIds
                                       AND IsWon = True GROUP BY AccountId];
    
    // Make sure AggregateResult isn't null then
    // Loop through AggregateResult object and add Ids and fields to updateHouseholds list
    If(!rollupResults.isEmpty()){
        For(AggregateResult result : rollupResults){
            
            // Initialize a temp Account object to store the information
            Account tempAcct = new Account();
          
            // Need to make sure that there is information for each field
            tempAcct.Id = (Id)result.get('AccountId'); // technically, an opportunity shouldn't exist without an AccountId
            If((Decimal)result.get('TotalAmount') != null){
                tempAcct.Cumulative_Gift__c = (Decimal)result.get('TotalAmount');}
            If((Date)result.get('LastGift') != null){
                tempAcct.Last_Gift_Date__c = (Date)result.get('LastGift');}
            If((Date)result.get('FirstGift') != null){
                tempAcct.First_Gift_Date__c = (Date)result.get('FirstGift');}
            If((Decimal)result.get('LargestGift') != null){
                tempAcct.Largest_Gift_Amount__c = (Decimal)result.get('LargestGift');}
          
          // Add the temp Account to the update list
          updateHouseholds.add(tempAcct);
      }
    }
    // Update Household list
    update updateHouseholds;
}
