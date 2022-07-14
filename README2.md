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

### Step0 - Before you start (Pre-requisites)

These are the key pre-requisites to deploy this solution:
1. When you access the lab, a virtual machine will startup with the PowerShell logon task.
![Log on task](/images/logon-task-start.jpg)
2. While the powershell logon task runs in background, log in to the Azure portal using the `Microsoft Edge browser` shortcut and the credentials provided in the lab guide.
3. In the welcome window that appears, please select `Maybe Later`. 
![Portal Maybe Later](/images/maybe-later-azure-homepage.jpg)
4. Now, go to the `Resource groups` option under `Navigate`, and open the `Intelligent` resource group that we will use for the rest of this demo. You will notice there are already few resources present. 
![Portal Maybe Later](/images/few-resources.jpg)
5. Go back to the powershell window and wait for a few minutes as we manually need to authorize two API connections.











