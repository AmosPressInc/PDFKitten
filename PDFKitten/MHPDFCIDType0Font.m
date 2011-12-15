#import "MHPDFCIDType0Font.h"


@implementation MHPDFCIDType0Font

- (NSString *)stringWithPDFString:(CGPDFStringRef)pdfString
{
	size_t length = CGPDFStringGetLength(pdfString);
	const unsigned char *cid = CGPDFStringGetBytePtr(pdfString);
    NSMutableString *result = [[NSMutableString alloc] init];
	for (int i = 0; i < length; i+=2) {
		char unicodeValue = cid[i+1];
        [result appendFormat:@"%C", unicodeValue];
	}
    return result;
}

@end
