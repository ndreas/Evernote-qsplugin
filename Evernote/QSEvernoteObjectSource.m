//
//  QSEvernoteObjectSource.m
//  Evernote
//
//  Created by Andreas Johansson on 2012-08-19.
//  Copyright (c) 2012 stdin.se. All rights reserved.
//

#import "QSEvernoteObjectSource.h"

@implementation QSEvernoteObjectSource


/*
 Loads right arrow children for Evernote
 */
- (BOOL)loadChildrenForObject:(QSObject *)object {
    if (!QSAppIsRunning(kQSEvernoteBundle)) {
        return NO;
    }
    
    NSMutableArray *children = [NSMutableArray arrayWithCapacity:1];
    
    if ([object.primaryType isEqualToString:NSFilenamesPboardType]) {
        QSEvernoteNotebookParser *notebookParser = [[[QSEvernoteNotebookParser alloc] init] autorelease];
        [children addObjectsFromArray:[notebookParser allNotebooks]];
        
        [object setChildren:children];
        return YES;
    } else if ([object.primaryType isEqualToString:kQSEvernoteNotebookType]) {
        QSEvernoteNoteParser *noteParser = [[[QSEvernoteNoteParser alloc] init] autorelease];
        [children addObjectsFromArray:[noteParser notesInNotebook:object]];
        
        [object setChildren:children];
    }

    return NO;
}


/*
 All objects handled by this source have children
 */
- (BOOL)objectHasChildren:(QSObject *)object {
    if ([object.primaryType isEqualToString:kQSEvernoteNoteType]) {
        return NO;
    } else {
        return QSAppIsRunning(kQSEvernoteBundle);
    }
}

/*
 Sets the icons for the notebooks
 */
- (void)setQuickIconForObject:(QSObject *)object {
    if ([object.primaryType isEqualToString:kQSEvernoteNotebookType]) {
        [object setIcon:[QSResourceManager imageNamed:kQSEvernoteBundle]];
    } else if ([object.primaryType isEqualToString:kQSEvernoteNoteType]) {
        [object setIcon:[QSResourceManager imageNamed:kQSEvernoteBundle]];
    }
}


@end