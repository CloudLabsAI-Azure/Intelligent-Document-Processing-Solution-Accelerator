![MSUS Solution Accelerator](./images/MSUS%20Solution%20Accelerator%20Banner%20Two_981.png)

# Intelligent Document Processing Solution Accelerator

Many organizations process different format of forms in various format. These forms go through a manual data entry process to extract all the relevant information before the data can be used by software applications. The manual processing adds time and opex in the process. The solution described here demonstrate how organizations can use Azure cognitive services to completely automate the data extraction and entry from pdf forms. The solution highlights the usage of the  **Form Recognizer** and **Azure Cognitive Search**  cognitive services. The pattern and template is data agnostic i.e. it can be easily customized to work on a custom set of forms as required by a POC, MVP or a demo. The demo also scales well through different kinds of forms and supports forms with multiple pages. 

## Architecture

![Architecture Diagram](/images/architecture.png)

## Process-Flow

* Receive forms from Email or upload via the custom web application
* The logic app will process the email attachment and persist the PDF form into blob storage
  * Uploaded Form via the UI will be persisted directly into blob storage
* Event grid will trigger the Logic app (PDF Forms processing)
* Logic app will
  * Convert the PDF (Azure function call)
  * Classify the form type using Custom Vision
  * Perform the blob operations organization (Azure Function Call)
* Cognitive Search Indexer will trigger the AI Pipeline
  * Execute standard out of the box skills (Key Phrase, NER)
  * Execute custom skills (if applicable) to extract Key/Value pair from the received form
  * Execute Luis skills (if applicable) to extract custom entities from the received form
  * Execute CosmosDb skills to insert the extracted entities into the container as document
* Custom UI provides the search capability into indexed document repository in Azure Search

## Deployment

Note: Most of the resources of this solution would have been already deployed.

### STEP 0 - Before you start (Pre-requisites)

These are the key pre-requisites to deploy this solution:
1. When you access the lab, a virtual machine will startup with the PowerShell logon task.


![Log on task](/images/logon-task-start.jpg)

2. While the powershell logon task runs in background, log in to the Azure portal using the **Microsoft Edge browser** shortcut and the credentials provided in the lab guide.

3. In the welcome window that appears, please select **Maybe Later**. 


![Portal Maybe Later](/images/maybe-later-azure-homepage.jpg)

4. Now, select the **Resource groups** icon under **Navigate**. 


![Open RGs](/images/idp-azure-home-page.jpg)

5. Open the **Intelligent** resource group that we will use for the rest of this demo.


![Select Intelligent RG](/images/select-RG.jpg)

6. You will notice there are already few resources present. 


![Few resources present in RG](/images/few-resources.jpg)

7. Go back to the PowerShell window and wait for a few minutes as we manually need to authorize two API connections.




### STEP 1 - Authorize Event Grid API Connection


1. Wait for the step in the script that states **STEP 12 - Create API Connection and Deploy Logic app**.


![Step 12 API Yellow](/images/Step12.jpg)

2. We need to authorize the API connection in two minutes. Once you see the message **Authorize idp<inject key="DeploymentID" enableCopy="false" />aegpi API Connection** in yellow, go to **Intelligent** resource group. 


![Authorize aegapi Yellow](/images/aegapi-authorize-yellow.jpg)

3. Search for the **idp<inject key="DeploymentID" enableCopy="false" />aegapi** resource in the search tab and click on it. This will now take you to a API connection page. 


![select aegapi in RG](/images/search-select-aegapi.jpg)

4. In the API connection blade, select **Edit API connection**. 


![edit aegapi](/images/edit-aegapi-blade.jpg)

5. Click on **Authorize** button to authorize. 


![Authorize aegapi](/images/authorize-aegapi-button.jpg)

6. In the new window that pops up, select the ODL/lab account. 


![Select Account](/images/aegapi-authorize-window.jpg)

7. **Save** ***(1)*** the connection and check for the notification stating **Successfully edited API connection** ***(2)***.


![Save aegapi connection](/images/aegapi-save.jpg)

8. Now go back to the **Overview** page and verify if the status shows **Connected**, else click on **Refresh** a few times as there could be some delays in the backend. 


![Verify aegapi connection](/images/verify-aegapi-connected.jpg)

9. When the status shows **Connected**, come back to the PowerShell window and click on any key to continue when you see the message **Press any key to continue**. 


![Continue after aegapi connection](/images/aegapi-press-continue.jpg)




### STEP 2 - Authorize Office 365 API Connection

1. We need follow the same procedure to authorize the Office 365 API as we did for the Event Grid API. We have to authorize the API connection in two minutes. Once you see the message **Authorize idp<inject key="DeploymentID" enableCopy="false" />o365api API Connection** in yellow, go to **Intelligent** resource group. 


![Authorize office365 api Yellow](/images/authorize-officeapi-yellow.jpg)

2. Search for the **idp<inject key="DeploymentID" enableCopy="false" />o365api** resource in the resources search tab and click on it. This will now take you to a API connection page. 


![select office365 api in RG](/images/Search-select-OfficeAPI.jpg)

3. In the API connection blade, select **Edit API connection**. 


![edit office365 api](/images/officeapi-edit-connection.jpg)

4. Click on **Authorize** button to authorize. 


![Authorize office365 api](/images/officeapi-authorize-button.jpg)

5. In the new window that pops up, select the ODL/lab account. 


![Select Account](/images/officeapi-authorize-window.jpg)

6. **Save** ***(1)*** the connection and check for the notification stating **Successfully edited API connection** ***(2)***. 


![Save office365 api connection](/images/officeapi-save.jpg)

7. Now go back to the **Overview** page and verify if the status shows **Connected**, else click on **Refresh** a few times as there could be some delays in the backend. 


![Verify office365 api connection](/images/officeapi-verify-connected.jpg)

8. When the status shows **Connected**, come back to the PowerShell window and click on any key to continue when you see the message **Press any key to continue**.


![Continue after office365 api connection](/images/officeapi-continue.jpg)


We have now authorized both the API connections. Go back to the PowerShell window and wait for the script execution to complete. Note that the PowerShell window will close once the script execution completes. Please wait for 10 minutes after the PowerShell run is complete, and then proceed to the next step.



## Acessing the Search UI

1. Go back to the **Intelligent** resource group. Then, search and select **idp<inject key="DeploymentID" enableCopy="false" />webapp**. 


![Select cognitive search RG](/images/SearchSelect-Webapp-RG.jpg)

2. In the App service page, click on the **URL** present in the Overview blade. This will open the Search UI/Web app in a new tab. 


![Open Web App Url](/images/Click-URL.jpg)

3. A webpage will load. Select **Search** in the top menu bar. 


![Search menu bar](/images/WebApp-Search.jpg)

4. Skip the tutorial by clicking on the **Skip Tutorial** popup. 


![Skip tutorial](/images/skipTutorial.jpg)

5. You can use the **Search tab** for searching the words from the forms uploaded and even explore each of the text cognitive skills by selecting them. 


![Search tab](/images/text-cognitive-skills.jpg)

6. We can even upload the files manually to cognitive search. Click on **Upload files** in the top menu bar, this will provide you with a user interface to upload the files. 


![Upload Files](/images/upload-files.jpg)

7. Drag and drop files into the red zone to add them to the upload list, or click anywhere within the red block to open a file dialog. 


![Drag drop files](/images/drag-drop-files.jpg)

8. Select the file to upload and wait for 5 minutes as the cognitive search enrichment pipeline runs every 5 minutes.

9. You can now go back to **Search** section and search for the word present in the file that was just uploaded.

We have now completed exploring the Cognitive Search UI.



## Creating Knowledge Store and working with Power BI report



### STEP 1 - Creating Knowledge Store

1. In the **Intelligent** resource group, search and select **idp<inject key="DeploymentID" enableCopy="false" />azs** cognitive search service reosurce.


![Select Cognitive search service](/images/Search-select-rg.jpg)

2. In the **Seacrh service** page, click on the **Import data** option which will lead you to a new page.


![Import data](/images/Import-data.jpg)

3. Choose **Existing data source** ***(1)*** from the drop down menu, then select the existing Data Source **processformsds** ***(2)*** and click on **Next: Add cognitive skills (optional)** ***(3)***. 


![Select Data source](/images/Connect-DataSource.jpg)

4. Click on the drop down button in the **Add cognitive skills** tab. 


![Select Drop Down](/images/drop-down.jpg)

5. Select the **idp<inject key="DeploymentID" enableCopy="false" />cs** ***(1)*** search service and click on the **Add enrichments** ***(2)*** drop down. 


![Attach Cognitive search](/images/select-attach-cognitiveservice.jpg)

6. Make sure to fill the below details as per the image below
   * Skillset name: **forms<inject key="DeploymentID" enableCopy="false" />-skillset** ***(1)***
   * Enable OCR and merge all text into **merged_content** field: **Check the box** ***(2)***
   * Source data field: **merged_content** ***(3)***
   * Enrichment granularity: **Pages (5000 characters chunks)** ***(4)***


![Add enrichments](/images/Add-enrichments2.jpg)

7. Scroll down and select the **Text Cognitive Skills** as per the image below. Then, select the **Save enrichments to a knowledge store** drop down.


![Verify Skills](/images/checkbox-and-nextSave.jpg)

8. In **Save enrichments** drop down, only select the below **Azure table projections**
   * Documents
   * Pages
   * Key phrases
   * Entities
  


![Table projections](/images/select-table-projection.jpg)

9. Now, we need the connection string of the storage account. Click on the **Choose an existing connection**, this will redirect to a new page to select the storage account. 


![Storage Account Connection String](/images/choose-connectionString.jpg)

10. Choose the **idp<inject key="DeploymentID" enableCopy="false" />sa** storage account.


![Select storage account](/images/select-storageAcc.jpg)

11. Select the container **processforms** ***(1)*** and click on **Select** ***(2)***.  


![Select Container](/images/select-container2.jpg)

12. Copy the Power BI parameters to a text file and save it, then select **Next: Customize target index**.  


![Copy the Power BI parameters](/images/next-targetIndex.jpg)

13. In this tab, enter the **Index name** as **forms<inject key="DeploymentID" enableCopy="false" />-index** ***(1)*** and select **Next: Create an indexer** ***(2)***. 


![Index details](/images/customize-index2.jpg)

14. Provide the following details for the indexer, 
    * Name: **forms<inject key="DeploymentID" enableCopy="false" />-indexer** ***(1)***
    * Schedule: **Custom** ***(2)***
    * Interval (minutes): **5** ***(3)***
    * Select **Submit** ***(4)*** to complete the process of creating **Knowledge Store** 


![Indexer details](/images/indexer-and-submit2.jpg)

15. Once submitted, click on the **Bell** icon in the top right section of the Azure portal to see the notifications. 


![Open Notification](/images/notification-open.jpg)

16. Select the text **Import successfully configured, click here to monitor the indexer progress** in the **Azure Cognitive Search** notiifcation. This will redirect you to **Indexer** page.


![Open Cognitive search Notification](/images/Import-Notification.jpg)

17. In this page, a run would have been **In progress** as in the below image. If you cannot see any run **In progress/Success**, click on refresh until you are able to see it. 


![Indexer Page Run In Progress](/images/Indexer-In-Progress.jpg)

18. After a few seconds the run status should show as **Success**, else feel free to click the **refresh button** until you see it.


![Indexer Page Run Success](/images/Indexer-Success.jpg)


We have now configured the Cognitive Search Knowledge Store.

### STEP 2 - Power BI Content Analytics

1. Open the Power BI report on the desktop with name **cognitive-search-content-analytics-template**.


![Power BI template desktop](/images/report-desktop.jpg)

2. If you get a popup window stating **Couldn't load the schema for the database model** and you are unable to close it like the below image. 


![Schema popup window](/images/schema-cant-load-popup-window.jpg)

3. Come to the taskbar and close the blank window. 


![Close error window](/images/Close-Error-Window.jpg)

4. Now go back to the Power BI window and try closing the popup. 


![Close Schema popup](/images/Cant-load-DB-schema.jpg)

5. Also close the **Collaborate and share**, and **Formatting just got easier** popups, if you get any. 


![Close Collaborate Share](/images/Close-Collaborate-share.jpg)



![Close Formatting popup](/images/Formatting-popup.jpg)

6. If you get a Power BI popup seeking for subscribing, please select **Maybe later** and then click on **Close**.


![Maybe Later in subscribe](/images/PBI-maybe-later.jpg)



![Maybe Later in subscribe](/images/close-thanks.jpg)


7. A popup with name **cognitive-search-content-analytics-template** will showup. Fill in the Power BI parameters that you previously copied according to the respective fields. 


![Provide Parameters](/images/enter-param.jpg)

8. To get the **StorageAccountSasUri**, please revert back to **Intelligent** resource group in Azure. Then search and select **idp<inject key="DeploymentID" enableCopy="false" />sa** storage account. 


![Search and select storage account](/images/search-select-storage-InRG.jpg)

9. Scroll down in the storage account left blade and select **Shared Access Signature** under **Security + networking**.


![Storage account SAS blade](/images/SAS-blade.jpg)

10. Check all the check boxes as shown in the below image.


![Check all boxes](/images/Check-AllBoxes.jpg)

11. Set the expiry date to next day and select your **Timezone** ***(1)***. Choose the Allowed protocols as **HTTP & HTTPS** ***(2)*** and click on **Generate SAS and connection string** ***(3)***.


![Set DateTime and Protocol](/images/DateTime-Protocol-GenerateSAS2.jpg)

12. Copy the **SAS token** and paste it in the Power BI popup window under **StorageAccountSasUri** and click on **Load**. 


![Copy SAS Token](/images/Copy-SASToken.jpg)

13. Another popup window might appear seeking storage account key. Go back to the storage account and in the left blade, search for **Access Keys** and select it. 


![Select Access Keys](/images/Select-AccessKeys.jpg)

14. Click on **Show keys** and copy the first key. 


![Show Keys](/images/showKey.jpg)


![Copy Key](/images/CopyKey.jpg)

15. Paste the copied key in the Power BI popup seeking it and select **Connect**.


![Account Keys Paste](/images/AccountKey.jpg)

16. A new popup with name **Refresh** will show up. Click on the **Continue** button that will appear.


![Refresh popup continue](/images/continue.jpg)

17. Wait for a few seconds for the report to load. Select the below **CognitiveSearch-KnowledgeStore-Analytics** tab and go through the above contents. 


![CognitiveSearch-KnowledgeStore-Analytics Tab](/images/CognitiveSearch-PBI-Tab.jpg)

18. Select the below **Keyphrase-Graph-Viewer** tab and go through the above contents. 


![Keyphrase-Graph-Viewer Tab](/images/keyphrase-viewer.jpg)


We have now explored Power BI Cognitive search content analytics report.

