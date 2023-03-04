
#Enable the recycle bin.  If already enabled, you will get an error message. You will get a warning message
Enable-ADOptionalFeature 'recycle bin feature' -Scope ForestOrConfigurationSet `
    -Target (get-adforest).rootdomain -server (get-adforest).domainnamingmaster `
        -Confirm:$false