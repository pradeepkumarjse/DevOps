SELECT	
   DISTINCT requestParameters['bucketName'],eventTime,eventSource,eventName,	
sourceIPAddress,recipientAccountId
FROM
    ca05adf0
    WHERE eventSource = 's3.amazonaws.com' AND 	
userIdentity.accountid = '' 
 AND element_at(requestParameters, 'bucketName') IS NOT NULL
    AND element_at(requestParameters, 'bucketName') IN ('slodispatch', 'slosales', 'sloimpoil', 'sloimpmn', 'sloimplpo', 'sloimpimsque', 'sloimpalm', 'sloimpac') AND
    eventName IS NOT NULL AND eventName IN ('PutObject','GetObject')
    AND
eventTime > '2024-04-19 22:00:22.000';
