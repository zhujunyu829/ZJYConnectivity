//
//  JoinRoomFoundView.h
//  MouseBattle
//
//  Created by ruibo on 16/4/21.
//  Copyright © 2016年 ruibo. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MCPeerID;

@interface JoinRoomFoundView : UIView

@property(nonatomic, copy) void(^choos)(MCPeerID* peerID);
-(void)addPeerIdAndReload:(MCPeerID*)peerId;

@end
