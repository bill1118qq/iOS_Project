//
//  XPathUpdate.m
//
//
//  Created by Cao Liang on 1/2/2013.
//  Copyright 2013 . All rights reserved.
//  mail:bill1118qq@gmail.com

#import <libxml/tree.h>
#import <libxml/parser.h>
#import <libxml/HTMLparser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>
#import <libxml/HTMLtree.h>

#import "XPathUpdate.h"

static void update_xpath_nodes(xmlNodeSetPtr nodes, const xmlChar* value) {
    int size;
    int i;
    
    assert(value);
    size = (nodes) ? nodes->nodeNr : 0;

    for(i = size - 1; i >= 0; i--) {
        assert(nodes->nodeTab[i]);
        
        xmlNodeSetContent(nodes->nodeTab[i], value);
        if (nodes->nodeTab[i]->type != XML_NAMESPACE_DECL)
            nodes->nodeTab[i] = NULL;
    }
}


static void PerformXPathUpdate(xmlDocPtr doc, NSString *query, NSString *newValue)
{
    xmlXPathContextPtr xpathCtx;
    xmlXPathObjectPtr xpathObj;
    
    /* Create xpath evaluation context */
    xpathCtx = xmlXPathNewContext(doc);
    if(xpathCtx == NULL)
    {
        NSLog(@"Unable to create XPath context.");
        return;
    }
    
    /* Evaluate xpath expression */
    xpathObj = xmlXPathEvalExpression((xmlChar *)[query cStringUsingEncoding:NSUTF8StringEncoding], xpathCtx);
    if(xpathObj == NULL) {
        NSLog(@"Unable to evaluate XPath.");
        xmlXPathFreeContext(xpathCtx);
        return;
    }
    
    xmlNodeSetPtr nodes = xpathObj->nodesetval;
    if (!nodes)
    {
        NSLog(@"Nodes was nil.");
        xmlXPathFreeObject(xpathObj);
        xmlXPathFreeContext(xpathCtx);
        return;
    }

	update_xpath_nodes(nodes, (xmlChar *)[newValue cStringUsingEncoding:NSUTF8StringEncoding]);
    /* Cleanup */
    xmlXPathFreeObject(xpathObj);
    xmlXPathFreeContext(xpathCtx);
    
    return;
}

NSData *PerformHTMLXPathUpdate(NSData *document, NSString *query, NSString *newValue)
{
    xmlDocPtr doc;
    xmlChar *html_buf;
    int len = [document length];

    doc = htmlReadMemory([document bytes], (int)[document length], "", NULL, HTML_PARSE_NOWARNING | HTML_PARSE_NOERROR);
  
    if (doc == NULL)
    {
      NSLog(@"Unable to parse.");
      return nil;
    }
    NSArray *pathArray =  NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[pathArray objectAtIndex:0] stringByAppendingPathComponent:@"tmp.html"];

    PerformXPathUpdate(doc, query, newValue);
    html_buf = malloc(len);

    htmlSaveFile([filePath cStringUsingEncoding:NSUTF8StringEncoding], doc);

    document = [NSData dataWithContentsOfFile:filePath];
    xmlFreeDoc(doc);
    free(html_buf);
    return document;
}
