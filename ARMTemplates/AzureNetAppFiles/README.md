# azure
ARM Templates for Azure NetApp Files

Use this template to provision ANF with Cross Region Replication (CRR). This template creates ANF account, capacity pool and volume in source region. It also creates account, capacity pool and replication volume in destination regions. Template uses the existing Vitual Networks and delegated subnets in source and destination regions. 

How to Use This Template:

Templates include master template, nested ARM templates and parameter files. There is a separate template for each ANF resources including ANF Account, ANF Capacitypools, ANF Volume and ANF Replication Volume. Parameter file is prepoluated with default values. Nested template requires deploying it from remote repository. 

ANF requires explicit authorization for replication. ANF provides REST API to authorize the source replication. Since we cannot call REST API directly from ARM Template, this template leverages the new preview feature deploymentscripts resource which allows execution of deployment scripts in template deployment.

Quick Links:

Using Netsted Templates : https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/linked-templates
Cross-region replication of ANF volumes: https://docs.microsoft.com/en-us/azure/azure-netapp-files/cross-region-replication-introduction
Requirements and considerations for cross-region replication: https://docs.microsoft.com/en-us/azure/azure-netapp-files/cross-region-replication-requirements-considerations
Microsoft.NetApp resource types to define ARM Template: https://docs.microsoft.com/en-us/azure/templates/microsoft.netapp/allversions
