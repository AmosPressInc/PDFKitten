# Kurt the PDFKitten

A framework for searching PDF documents on iOS.
Fork from the impressive work of KurtCode : https://github.com/KurtCode/PDFKitten

### About my fork
For my project, I need to search through all the document. So, from the original repo, here are my modifications :
• Background parsing when you parse all the document
• The output data is changed to a dictionary which contains array for keys (the pages). This is more suitable when you need to access selections for a specific page.
• Renaming of all the core files, with reference to the work of KurtCode. This renaming is to make life easier when you include the files into a big bunch of others files.
• Integrate MHLog to avoid multiple NSLog in production
• The scan for a single page stays in main thread

### Why?

iOS, up to and including the current fifth version, does not provide any public APIs for searching PDF documents, or determining where on a page a given word is drawn. Any developer aiming to provide these features in an app must use low-level Core Graphics APIs, and keep track of the stateful process of laying out the content of the page.

This project is meant to facilitate this by implementing a complete workflow, taking as input a PDF document, a keyword string, and returning a set of selections that can be drawn on top of the PDF document.

### How?

First, create a new instance of the scanner.

```
	MHPDFScanner *scanner = [[MHPDFScanner alloc] init];
```

Set a keyword (case-insensitive) and scan a page.

```
	scanner.keyword = @"happiness";
	CGPDFPageRef page = CGPDFDocumentGetPage(document, 1);
	[scanner scanPage:page];
```

Finally, scan the page and draw the selections.

```
	// DEPRECATED
	for (MHPDFSelection *selection in scanner.selections)
	{
		// draw selection
	}

	NSArray *selections = [scanner.selectionsDic objectForKey:[NSNumber numberWithUnsignerInteger:currentPage]];
	for (MHPDFSelection *selection in selections)
	{
		// draw selection
	}
```

### Limitations

The PDF specification is huge, allowing for different fonts, text encodings et cetera. This means strict design is a must, and thorough testing is needed. At this point, this project is not fully compatible with all font types, and especially suppert for non-latin characters will require further development.


### License and Warranty

This software is provided as is, meaning that we are not responsible for the results of its use.