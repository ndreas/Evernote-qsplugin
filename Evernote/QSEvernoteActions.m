//
//  QSEvernoteActionProvider.m
//  Evernote
//
//  Created by Andreas Johansson on 2012-08-25.
//  Copyright (c) 2012 stdin.se. All rights reserved.
//

#import "QSEvernoteActions.h"

@implementation QSEvernoteActions


- (QSObject *) search:(QSObject *)directObj for:(QSObject *)indirectObj {
    NSString *query = nil;

    if ([directObj.primaryType isEqualToString:QSFilePathType]) {
        query = [self escapeString:[indirectObj objectForType:QSTextType]];
    } else if ([directObj.primaryType isEqualToString:kQSEvernoteNotebookType]) {
        query = [NSString stringWithFormat:
                 @"%@ %@",
                 [self notebookQuery:directObj],
                 [self escapeString:[indirectObj objectForType:QSTextType]]];
    }

    if (query) {
        [self setQueryStringInFrontmost:query];
    }

    return nil;
}


- (QSObject *) openNotebook:(QSObject *)directObj {
    NSString *commands = [NSString stringWithFormat:
                          @"set mywin to open collection window\nset query string of mywin to \"%@\"\nactivate",
                          [self notebookQuery:directObj]];
    [self tellEvernote:commands];
    return nil;
}


- (QSObject *) revealNotebook:(QSObject *)directObj {
    [self setQueryStringInFrontmost:[self notebookQuery:directObj]];
    return nil;
}


- (QSObject *) openTag:(QSObject *)directObj {
    NSString *commands = [NSString stringWithFormat:
                          @"set mywin to open collection window\nset query string of mywin to \"%@\"\nactivate",
                          [self tagQuery:directObj]];
    [self tellEvernote:commands];
    return nil;
}


- (QSObject *) revealTag:(QSObject *)directObj {
    [self setQueryStringInFrontmost:[self tagQuery:directObj]];
    return nil;
}


- (QSObject *) openNote:(QSObject *)directObj {
    EvernoteNote *note = (EvernoteNote *)[directObj objectForType:kQSEvernoteNoteType];
    
    EvernoteApplication *evernote = [SBApplication applicationWithBundleIdentifier:kQSEvernoteBundle];
    
    [evernote openNoteWindowWith:note];
    [evernote activate];
    return nil;
}


- (QSObject *) revealNote:(QSObject *)directObj {
    EvernoteNote *note = (EvernoteNote *)[directObj objectForType:kQSEvernoteNoteType];

    NSString *query = [NSString stringWithFormat:
                       @"intitle:\\\"%@\\\" notebook:\\\"%@\\\" created:%@",
                       note.title,
                       note.notebook.name,
                       [note.creationDate descriptionWithCalendarFormat:@"%Y%m%dT%H%M%s"
                                                               timeZone:nil
                                                                 locale:nil]
                       ];

    [self setQueryStringInFrontmost:query];

    return nil;
}


- (NSArray *) validActionsForDirectObject:(QSObject *)directObj indirectObject:(QSObject *)indirectObj {
    if ([directObj.primaryType isEqual:kQSEvernoteNotebookType]) {
        return [NSArray arrayWithObjects:
                @"QSEvernoteOpenNotebook",
                @"QSEvernoteRevealNotebook",
                nil];
    } else if ([directObj.primaryType isEqual:kQSEvernoteTagType]) {
        return [NSArray arrayWithObjects:
                @"QSEvernoteOpenTag",
                @"QSEvernoteRevealTag",
                nil];
    } else if ([directObj.primaryType isEqual:kQSEvernoteNoteType]) {
        return [NSArray arrayWithObjects:
                @"QSEvernoteOpenNote",
                @"QSEvernoteRevealNote",
                @"QSEvernoteOpenNotebook",
                @"QSEvernoteRevealNotebook",
                nil];
    }
    
    return nil;
}


- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)directObj {
    if ([action isEqualToString:@"QSEvernoteSearch"] || [action isEqualToString:@"QSEvernoteSearchNotebook"]) {
        return [NSArray arrayWithObject:[QSObject textProxyObjectWithDefaultValue:@""]];
    }

    return nil;
}


- (NSString *) notebookQuery:(QSObject *)notebook {
    return [NSString stringWithFormat:@"notebook:\\\"%@\\\"",
            [notebook objectForType:kQSEvernoteNotebookType]];
}


- (NSString *) tagQuery:(QSObject *)notebook {
    return [NSString stringWithFormat:@"tag:\\\"%@\\\"",
            [[notebook objectForType:kQSEvernoteTagType] substringFromIndex:1]];
}



/*
 Sets the query string of the frontmost Evernote collection window to
 the given query, and if there is no Evernote collection window available,
 it creates a new.
 
 This method does not escape the queryString.
 */
- (void) setQueryStringInFrontmost:(NSString *)queryString {
    NSString *commands = [NSString stringWithFormat:

                          @"set targetWindow to missing value\n"

                          "repeat with win in windows\n"
                          "  if class of win = collection window and win is visible then\n"
                          "    set targetWindow to win\n"
                          "    exit repeat\n"
                          "  end if\n"
                          "end repeat\n"

                          "if targetWindow is missing value then\n"
                          "  set targetWindow to open collection window\n"
                          "end if\n"

                          "set query string of targetWindow to \"%@\"\n"
                          "set winIndex to index of targetWindow\n"

                          "tell application \"System Events\"\n"
                          "  tell process \"Evernote\"\n"
                          "    perform action \"AXRaise\" of window winIndex\n"
                          "  end tell\n"
                          "end tell\n"

                          "activate\n",

                          queryString];

    [self tellEvernote:commands];
}

- (void) tellEvernote:(NSString *)commands {
    NSString *source = [NSString stringWithFormat:
                        @"tell application \"Evernote\"\n%@\nend tell",
                        commands];
    
    NSAppleScript *scriptObject = [[[NSAppleScript alloc] initWithSource:source] autorelease];
    NSDictionary *errors;
    [scriptObject executeAndReturnError:&errors];
}


/*
 Escapes all special characters in a string before usage in an Applescript string
 */
- (NSString *) escapeString:(NSString *)string {
    NSString *escapeString = QSApplescriptStringEscape;

    NSUInteger i;
    for (i = 0; i < [escapeString length]; i++){
        NSString *thisString = [escapeString substringWithRange:NSMakeRange(i,1)];
        string = [[string componentsSeparatedByString:thisString] componentsJoinedByString:[@"\\" stringByAppendingString:thisString]];
    }
    return string;
}


@end
