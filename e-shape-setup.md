```mermaid
%%{init: {'theme':'base',
    'themeVariables': {
      'primaryColor': '#abc',
      'lineColor': '#123',
      'secondaryColor': '#060',
      'tertiaryColor': '#ddd',
      'fontSize': '56px'
    }}
}%%
graph LR
    subgraph WEkEO
    Oper[Operational SmartMet-server]---WEkEOvs
    Dev[Development SmartMet-server]---WEkEOvs
    Web[WWW-apache;html+js]---WEkEOvs
    end
    subgraph Sodankylä
    Oper---S3[Cloud Storage]
    end
```
