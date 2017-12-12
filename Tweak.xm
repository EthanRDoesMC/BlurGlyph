#define PREFS_PATH @"/var/mobile/Library/Preferences/me.chewitt.fingal.plist"

#import "Headers.h"
#import "NSArray+Reverse.h"
#import "UIImage+animatedGIF.h"

static NSArray *activeThemes;

%hook SBIconImageView
// A simple control f will keep the names consistent
// if referencing the tweak by name use 'blurglyph'
%property (nonatomic,retain) UIImageView *blurglyphAnimatedIconView; // Need to use our own image view as the icon image view messes stuff up

- (void)setIcon:(SBIcon *)icon location:(int)location animated:(BOOL)animated {
	%orig;

	if([icon isKindOfClass:%c(SengSBIcon)] || [icon isKindOfClass:%c(SBFolderIcon)]) return; // ignore some icons
	
//idk what seng is but you know what fallback code is nice

	// get the highest priority theme for this icon
	NSString *themeUsedForThisIcon = @"";
	for(NSString *activeTheme in activeThemes) {
		NSString *blurglyphDir = [NSString stringWithFormat:@"/var/mobile/Library/blurglyph/%@/Icons/%@.png",activeTheme,icon.nodeIdentifier];
		if([[NSFileManager defaultManager] fileExistsAtPath:blurglyphDir]) //update to anemone
			themeUsedForThisIcon = activeTheme; // toggling themes and then individual icons will be tough but worth it
	}

	if(![themeUsedForThisIcon isEqualToString:@""]) { // this icon is being themed
		self.layer.contents = nil; // remove the original icon display
        if(self.blurglyphAnimatedIconView == nil) {// create image view if doesn't exist and mask appropriately
			self.blurglyphAnimatedIconView = [[UIImageView alloc] initWithFrame:self.bounds];
			[self.blurglyphAnimatedIconView setBackgroundColor:[UIColor clearColor]];
			self.blurglyphAnimatedIconView.layer.masksToBounds = YES;
			self.blurglyphAnimatedIconView.userInteractionEnabled = NO;
			UIImage *_maskingImage = self.contentsImage;
			CALayer *_maskingLayer = [CALayer layer];
			_maskingLayer.frame = self.blurglyphAnimatedIconView.bounds;
			[_maskingLayer setContents:(id)[_maskingImage CGImage]];
			[self.blurglyphAnimatedIconView.layer setMask:_maskingLayer];
			[self addSubview:self.blurglyphAnimatedIconView];
		}
		//load the gif as an image using Rob Mayoff's UIImage+animatedGIF (http://github.com/mayoff/uiimage-from-animated-gif/)
		NSString *src = [NSString stringWithFormat:@"file:///var/mobile/Library/Fingal/%@/Icons/%@.gif",themeUsedForThisIcon,icon.nodeIdentifier];
		self.fingalAnimatedIconView.image = [UIImage animatedImageWithAnimatedGIFURL:[NSURL URLWithString:src]];
	}
	else { // this icon isnt being themed so remove custom icon view
		if(self.fingalAnimatedIconView != nil)
			[self.fingalAnimatedIconView removeFromSuperview];
		self.fingalAnimatedIconView = nil;
	}
}

-(void) setFrame:(CGRect)f {
	%orig;
	// resize if frame changes (accounts for seng)
	if(self.fingalAnimatedIconView != nil) {
		if(!CGRectEqualToRect(self.fingalAnimatedIconView.frame, self.bounds)) {
			self.fingalAnimatedIconView.frame = self.bounds;
			UIImage *_maskingImage = self.contentsImage;
			CALayer *_maskingLayer = [CALayer layer];
			_maskingLayer.frame = self.fingalAnimatedIconView.bounds;
			[_maskingLayer setContents:(id)[_maskingImage CGImage]];
			[self.fingalAnimatedIconView.layer setMask:_maskingLayer];
		}
	}
}

%end


%ctor {
	// load in prefs on startup
	activeThemes = [[NSDictionary dictionaryWithContentsOfFile:PREFS_PATH][@"enabledThemes"] reversedArray];
}


//dec 12 6am notes
//SO MUCH CAMELCASE
//todo:
//finish converting class names
//move directories to anemone themes
//hope that doesn't cause issues
//possibilities: create an app/prefbundle that moves glyph themes that the user picks to an alt folder
//todo next: hook into SBFolderIconBackgroundView/SBIconBlurryBackgroundView
