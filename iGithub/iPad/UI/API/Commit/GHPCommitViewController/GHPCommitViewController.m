//
//  GHPCommitViewController.m
//  iGithub
//
//  Created by Oliver Letterer on 02.07.11.
//  Copyright 2011 Home. All rights reserved.
//

#import "GHPCommitViewController.h"
#import "GHPCollapsingAndSpinningTableViewCell.h"
#import "GHPDiffViewTableViewCell.h"
#import "GHViewCloudFileViewController.h"

@implementation GHPCommitViewController

@synthesize repository=_repository, commitID=_commitID, commit=_commit;

#pragma mark - setters and getters

- (void)setCommit:(GHCommit *)commit {
    if (commit != _commit) {
        _commit = commit;
        
        if (self.isViewLoaded) {
            [self.tableView reloadData];
        }
        
        self.title = _commit.message;
    }
}

- (void)setRepository:(NSString *)repository commitID:(NSString *)commitID {
    
    _repository = [repository copy];
    _commitID = [commitID copy];
    self.commit = nil;
    self.isDownloadingEssentialData = YES;
    [GHCommit commit:_commitID onRepository:_repository completionHandler:^(GHCommit *commit, NSError *error) {
        self.isDownloadingEssentialData = NO;
        if (error) {
            [self handleError:error];
        } else {
            self.commit = commit;
        }
    }];
}

#pragma mark - Initialization

- (id)initWithRepository:(NSString *)repository commitID:(NSString *)commitID {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        // Custom initialization
        [self setRepository:repository commitID:commitID];
    }
    return self;
}

#pragma mark - UIExpandableTableViewDatasource

- (BOOL)tableView:(UIExpandableTableView *)tableView canExpandSection:(NSInteger)section {
    return ((section >= 0) && (section <= (self.commit.modified.count-1)) && self.commit.modified.count > 0);
}

- (BOOL)tableView:(UIExpandableTableView *)tableView needsToDownloadDataForExpandableSection:(NSInteger)section {
    return NO;
}

- (UITableViewCell<UIExpandingTableViewCell> *)tableView:(UIExpandableTableView *)tableView expandingCellForSection:(NSInteger)section {
    GHPCollapsingAndSpinningTableViewCell *cell = [self defaultPadCollapsingAndSpinningTableViewCellForSection:section];
    
    GHCommitFileInformation *fileInfo = [self.commit.modified objectAtIndex:section];
    
    cell.textLabel.text = fileInfo.filename;
    
    return cell;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (!self.commit) {
        return 0;
    }
    // Return the number of sections.
    NSInteger count = 0;
    count += self.commit.modified.count;
    count += self.commit.added.count > 0;
    count += self.commit.removed.count > 0;
    
    return count;
}

// modified     0                               ->              self.commit.modified.count-1
// added        self.commit.modified.count
// removed      self.commit.modified.count + (self.commit.added.count > 0)

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section >= 0 && section <= self.commit.modified.count-1 && self.commit.modified.count>0) {
        // modified:    filename + diff
        return 2;
    } else if (section == self.commit.modified.count && self.commit.added.count > 0) {
        // added
        return self.commit.added.count;
    } else if (section == (self.commit.modified.count + (self.commit.added.count > 0))) {
        // removed
        return self.commit.removed.count;
    }
    
    // Return the number of rows in the section.
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == self.commit.modified.count && self.commit.added.count > 0) {
        // added
        GHPDefaultTableViewCell *cell = [self defaultTableViewCellForRowAtIndexPath:indexPath withReuseIdentifier:@"GHPDefaultTableViewCell"];
        cell.textLabel.text = [self.commit.added objectAtIndex:indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        return cell;
    } else if (indexPath.section == (self.commit.modified.count + (self.commit.added.count > 0))) {
        // removed
        
        GHPDefaultTableViewCell *cell = [self defaultTableViewCellForRowAtIndexPath:indexPath withReuseIdentifier:@"GHPDefaultTableViewCell"];
        cell.textLabel.text = [self.commit.removed objectAtIndex:indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        return cell;
    } else if (indexPath.section >= 0 && indexPath.section <= self.commit.modified.count-1) {
        // modified file
        static NSString *CellIdentifier = @"GHPDiffViewTableViewCell";
        
        GHPDiffViewTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[GHPDiffViewTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        GHCommitFileInformation *fileInfo = [self.commit.modified objectAtIndex:indexPath.section];
        
        cell.diffView.diffString = fileInfo.diff;
        
        // Configure the cell...
        
        return cell;
    }
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == self.commit.modified.count && self.commit.added.count > 0) {
        return UITableViewAutomaticDimension;
    } else if (section == (self.commit.modified.count + (self.commit.added.count > 0))) {
        return UITableViewAutomaticDimension;
    } else if (section == 0 && self.commit.modified.count > 0) {
        return UITableViewAutomaticDimension;
    }
    return 0.0f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == self.commit.modified.count && self.commit.added.count > 0) {
        return NSLocalizedString(@"Added Files", @"");
    } else if (section == (self.commit.modified.count + (self.commit.added.count > 0))) {
        return NSLocalizedString(@"Removed Files", @"");
    } else if (section == 0 && self.commit.modified.count > 0) {
        return NSLocalizedString(@"Modified Files", @"");
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section >= 0 && indexPath.section <= self.commit.modified.count-1 && indexPath.row == 1 && self.commit.modified.count > 0) {
        GHCommitFileInformation *fileInfo = [self.commit.modified objectAtIndex:indexPath.section];
        
        return [GHPDiffViewTableViewCell heightWithContent:fileInfo.diff];
    }
    return UITableViewAutomaticDimension;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == self.commit.modified.count && self.commit.added.count > 0) {
        NSString *filename = [self.commit.added objectAtIndex:indexPath.row];
        
        NSString *URL = [filename stringByDeletingLastPathComponent];
        NSString *base = [filename lastPathComponent];
        
        GHViewCloudFileViewController *fileViewController = [[GHViewCloudFileViewController alloc] initWithRepository:self.repository 
                                                                                                                  tree:self.commitID 
                                                                                                              filename:base 
                                                                                                           relativeURL:URL];
        
        if (self.advancedNavigationController) {
            [self.advancedNavigationController pushViewController:fileViewController afterViewController:self animated:YES];
        } else if (self.navigationController) {
            [self.navigationController pushViewController:fileViewController animated:YES];
        }
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

#pragma mark - Keyed Archiving

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    [encoder encodeObject:_repository forKey:@"repository"];
    [encoder encodeObject:_commitID forKey:@"commitID"];
    [encoder encodeObject:_commit forKey:@"commit"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super initWithCoder:decoder])) {
        _repository = [decoder decodeObjectForKey:@"repository"];
        _commitID = [decoder decodeObjectForKey:@"commitID"];
        _commit = [decoder decodeObjectForKey:@"commit"];
    }
    return self;
}

@end
