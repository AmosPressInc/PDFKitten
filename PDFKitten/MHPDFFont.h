/*
 *	Implements generic behavior of a font.
 *
 *	Most likely used exclusively for subclassing, for Type 0, Type 1 etc.
 *
 *	Ideally, the subclasses are hidden from the user, who interacts with them through this facade class.
 *	
 */
#import <Foundation/Foundation.h>
#import "MHPDFFontDescriptor.h"
#import "MHPDFCMap.h"

@interface MHPDFFont : NSObject {
	MHPDFCMap *toUnicode;
	NSMutableDictionary *widths;
    MHPDFFontDescriptor *fontDescriptor;
	NSDictionary *ligatures;
	NSRange widthsRange;
}

/* Factory method returns a Font object given a PDF font dictionary */
+ (MHPDFFont *)fontWithDictionary:(CGPDFDictionaryRef)dictionary;

/* Initialize with a font dictionary */
- (id)initWithFontDictionary:(CGPDFDictionaryRef)dict;

/* Populate the widths array given font dictionary */
- (void)setWidthsWithFontDictionary:(CGPDFDictionaryRef)dict;

/* Construct a font descriptor given font dictionary */
- (void)setFontDescriptorWithFontDictionary:(CGPDFDictionaryRef)dict;

/* Given a PDF string, returns a Unicode string */
- (NSString *)stringWithPDFString:(CGPDFStringRef)pdfString;

/* Given a PDF string, returns a CID string */
- (NSString *)cidWithPDFString:(CGPDFStringRef)pdfString;

/* Returns the width of a charachter (optionally scaled to some font size) */
- (CGFloat)widthOfCharacter:(unichar)characher withFontSize:(CGFloat)fontSize;

/* Import a ToUnicode CMap from a font dictionary */
- (void)setToUnicodeWithFontDictionary:(CGPDFDictionaryRef)dict;

/* Unicode character with CID */
- (NSString *)stringWithCharacters:(const char *)characters;

@property (nonatomic, retain) MHPDFCMap *toUnicode;
@property (nonatomic, retain) NSMutableDictionary *widths;
@property (nonatomic, retain) MHPDFFontDescriptor *fontDescriptor;
@property (nonatomic, readonly) CGFloat minY;
@property (nonatomic, readonly) CGFloat maxY;
@property (nonatomic, readonly) NSDictionary *ligatures;
@property (nonatomic, readonly) CGFloat widthOfSpace;
@property (nonatomic, readonly) NSRange widthsRange;
@end
