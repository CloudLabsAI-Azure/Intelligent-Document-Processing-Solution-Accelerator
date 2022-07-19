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
2. While the powershell logon task runs in background, log in to the Azure portal using the `Microsoft Edge browser` shortcut and the credentials provided in the lab guide.
3. In the welcome window that appears, please select `Maybe Later`. 
![Portal Maybe Later](/images/maybe-later-azure-homepage.jpg)
4. Now, go to the `Resource groups` option under `Navigate`, and open the `Intelligent` resource group that we will use for the rest of this demo. You will notice there are already few resources present. 
![Few resources present in RG](/images/few-resources.jpg)
5. Go back to the PowerShell window and wait for a few minutes as we manually need to authorize two API connections.

### STEP 1 - Authorize `idp``aegapi` API Connection

1. Wait for the step in the script that states `STEP 12 - Create API Connection and Deploy Logic app`. 
![Step 12 API Yellow](/images/Step12.jpg)
2. We need to authorize the API connection in two minutes. Once you see the message `Authorize idpaegapi API Connection` in yellow, go to `Intelligent` resource group. 
![Authorize aegapi Yellow](/images/aegapi-authorize-yellow.jpg)
3. Search for the `idp``aegapi` resource in the search tab and click on it. This will now take you to a API connection page. (Image)
![select aegapi in RG](/images/search-select-aegapi.jpg)
4. In the API connection blade, select `Edit API connection`. (Image)
![edit aegapi](/images/edit-aegapi-blade.jpg)
5. Click on `Authorize` button to authorize. (Image)
![Authorize aegapi](/images/authorize-aegapi-button.jpg)
6. In the new window that pops up, select the ODL/lab account. (Image)
![Select Account](/images/aegapi-authorize-window.jpg)
7. `Save` the connection and check for the notification stating **Successfully edited API connection**. (Image)
![Save aegapi connection](/images/aegapi-save.jpg)
8. Now go back to the `Overview` page and verify if the status shows **Connected**, else click on `Refresh` a few times as there could be some delays in the backend. (Image)
![Verify aegapi connection](/images/verify-aegapi-connected.jpg)
9. When the status shows **Connected**, come back to the PowerShell window and click on any key to continue when you see the message `Press any key to continue`. (Image)
![Continue after aegapi connection](/images/aegapi-press-continue.jpg)

### STEP 2 - Authorize `idp``o365api` API Connection

1. We need follow the same procedure to authorize `idpo366api` as we did in the previous step. We have to authorize the API connection in two minutes. Once you see the message `Authorize idpo365api API Connection` in yellow, go to `Intelligent` resource group. 
![Authorize office365 api Yellow](/images/authorize-officeapi-yellow.jpg)
2. Search for the `idp``o365api` resource in the search tab and click on it. This will now take you to a API connection page. 
![select office365 api in RG](/images/officeapi-in-rg-intelligent.jpg)
3. In the API connection blade, select `Edit API connection`. 
![edit office365 api](/images/officeapi-edit-connection.jpg)
4. Click on `Authorize` button to authorize. 
![Authorize office365 api](/images/officeapi-authorize-button.jpg)
5. In the new window that pops up, select the ODL/lab account. 
![Select Account](/images/officeapi-authorize-window.jpg)
6. `Save` the connection and check for the notification stating **Successfully edited API connection**. 
![Save office365 api connection](/images/officeapi-save.jpg)
7. Now go back to the `Overview` page and verify if the status shows **Connected**, else click on `Refresh` a few times as there could be some delays in the backend. 
![Verify office365 api connection](/images/officeapi-verify-connected.jpg)
8. When the status shows **Connected**, come back to the PowerShell window and click on any key to continue when you see the message `Press any key to continue`. (Image)
![Continue after office365 api connection](/images/officeapi-continue.jpg)


We have now authorized both the API connections, wait for the script execution to complete. Note that the PowerShell window will close once the script execution completes.

## Creating Knowledge Store and working with Power BI report

### STEP 1 - Creating Knowledge Store

1. In the `Intelligent` resource group, search and select `idp666666azs` cognitive search service reosurce. (Image-SearchSelect)
2. In the **Seacrh service** page, click on the `Import data` option which will lead you to a new page. (Image-Import data)
3. Choose `Existing data source` from the drop down menu, then select the existing Data Source `processformsds` and clcik on `Next: Add cognitive skills (optional)` (Image-ConnectDS)
4. Click on the drop down button in the **Add cognitive skills** tab (Image-dropdown)
5. Select the `idpcs` search service and click on the `Add enrichments` drop down (Image-AttachCS)
6. Make sure to fill the below details as per the image 
   * Skillset name: `form<DID>skillset`
   * Enable OCR and merge all text into **merged_content** field: `Check the box`
   * Source data field: `merged_content`
   * Enrichment granularity: `Pages (5000 characters chunks)`
   (Image-AddEnrichements)
7. Scroll down and verify if skills are checked as per the image below, else select the skills according to the image. (Image-CheckboxNextSave)
8. In **Save enrichments** drop down, only select the below **Azure table projections**
   * Documents
   * Pages
   * Key phrases
   * Entities
   (Image-TableProjection)
9. Now, we need the connection string of the storage account. Click on the `Choose an existing connection`, this will redirect to a new page to select the storage account. (Image-ConnectionString)
10.  
