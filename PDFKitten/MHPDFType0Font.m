#import "MHPDFType0Font.h"
#import "MHPDFCIDType0Font.h"
#import "MHPDFCIDType2Font.h"


@interface MHPDFType0Font ()
@property (nonatomic, readonly) NSMutableArray *descendantFonts;
@end

@implementation MHPDFType0Font

/* Initialize with font dictionary */
- (id)initWithFontDictionary:(CGPDFDictionaryRef)dict
{
	if ((self = [super initWithFontDictionary:dict]))
	{
		CGPDFArrayRef dFonts;
		if (CGPDFDictionaryGetArray(dict, "DescendantFonts", &dFonts))
		{
			NSUInteger count = CGPDFArrayGetCount(dFonts);
			for (int i = 0; i < count; i++)
			{
				CGPDFDictionaryRef fontDict;
				if (!CGPDFArrayGetDictionary(dFonts, i, &fontDict)) continue;
				const char *subtype;
				if (!CGPDFDictionaryGetName(fontDict, "Subtype", &subtype)) continue;

				MHLog(@"Descendant font type %s", subtype);

				if (strcmp(subtype, "CIDFontType0") == 0)
				{
					// Add descendant font of type 0
					MHPDFCIDType0Font *font = [[MHPDFCIDType0Font alloc] initWithFontDictionary:fontDict];
					if (font) [self.descendantFonts addObject:font];
					[font release];
				}
				else if (strcmp(subtype, "CIDFontType2") == 0)
				{
					// Add descendant font of type 2
					MHPDFCIDType2Font *font = [[MHPDFCIDType2Font alloc] initWithFontDictionary:fontDict];
					if (font) [self.descendantFonts addObject:font];
					[font release];
				}
			}
		}
	}
	return self;
}

/* Custom implementation, using descendant fonts */
- (CGFloat)widthOfCharacter:(unichar)characher withFontSize:(CGFloat)fontSize
{
	for (MHPDFFont *font in self.descendantFonts)
	{
		CGFloat width = [font widthOfCharacter:characher withFontSize:fontSize];
		if (width > 0) return width;
	}
	return 0;
}

- (NSDictionary *)ligatures
{
    MHPDFFont *descendantFont = [self.descendantFonts lastObject];
    return descendantFont.ligatures;
}

- (MHPDFFontDescriptor *)fontDescriptor {
	MHPDFFont *descendantFont = [self.descendantFonts lastObject];
	return descendantFont.fontDescriptor;
}

- (CGFloat)minY
{
	MHPDFFont *descendantFont = [self.descendantFonts lastObject];
	return [descendantFont.fontDescriptor descent];
}

/* Highest point of any character */
- (CGFloat)maxY
{
	MHPDFFont *descendantFont = [self.descendantFonts lastObject];
	return [descendantFont.fontDescriptor ascent];
}

- (NSString *)stringWithPDFString:(CGPDFStringRef)pdfString
{
    NSMutableString *result;
	MHPDFFont *descendantFont = [self.descendantFonts lastObject];
    NSString *descendantResult = [descendantFont stringWithPDFString: pdfString];
    if (self.toUnicode) {
        unichar mapping;
        result = [[[NSMutableString alloc] initWithCapacity: [descendantResult length]] autorelease];
        for (int i = 0; i < [descendantResult length]; i++) {
            mapping = [self.toUnicode unicodeCharacter: [descendantResult characterAtIndex:i]];
            [result appendFormat: @"%C", mapping];
        }        
    } else {
        result = [NSMutableString stringWithString: descendantResult];
    }
    return result;
}

- (NSString *)cidWithPDFString:(CGPDFStringRef)pdfString {
    MHPDFFont *descendantFont = [self.descendantFonts lastObject];
    return [descendantFont stringWithPDFString: pdfString];
}


#pragma mark -
#pragma mark Memory Management

- (NSMutableArray *)descendantFonts
{
	if (!descendantFonts)
	{
		descendantFonts = [[NSMutableArray alloc] init];
	}
	return descendantFonts;
}

- (void)dealloc
{
	[descendantFonts release];
	[super dealloc];
}

@end
