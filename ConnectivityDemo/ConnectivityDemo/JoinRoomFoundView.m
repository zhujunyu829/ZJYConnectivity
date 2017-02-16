//
//  JoinRoomFoundView.m
//  MouseBattle
//
//  Created by ruibo on 16/4/21.
//  Copyright © 2016年 ruibo. All rights reserved.
//

#import "JoinRoomFoundView.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface JoinRoomFoundView()<UITableViewDataSource,UITableViewDelegate>
{
    NSMutableArray * _peerIdArr;
    UITableView * _mainTabelView;

}
@end

@implementation JoinRoomFoundView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initData];
        [self initView];
    }
    return self;
}


-(void)initData
{
    _peerIdArr = [NSMutableArray array];
}

-(void)initView
{
    [self addMainTable];
}

#pragma mark 添加主表格
-(void)addMainTable
{
    _mainTabelView = [[UITableView alloc]initWithFrame:CGRectMake(0, 20, self.frame.size.width, self.frame.size.height-20) style:UITableViewStylePlain];
    
    _mainTabelView.dataSource = self;
    _mainTabelView.delegate = self;
    [self addSubview:_mainTabelView];
}

//加入一个设备的peerId
-(void)addPeerIdAndReload:(MCPeerID*)peerId
{
    [_peerIdArr addObject:peerId];
    [_mainTabelView reloadData];
}

#pragma mark 一共有多少组
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

#pragma mark 每组的高度
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}

#pragma mark 一共有多少行
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_peerIdArr count];
}

#pragma mark 每个表格的高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

#pragma mark 设置组名
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"请选择你想加入的设备";
}

#pragma mark 设置每个表格
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier;
    
    CellIdentifier = @"teachOrderTraceViewClassInfoCell";
    UITableViewCell * cell  = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    MCPeerID * onePeerId = [_peerIdArr objectAtIndex:indexPath.row];
    NSString * displayName = onePeerId.displayName;
    cell.textLabel.text = displayName;
    return cell;

}

//选择了一行
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCPeerID * selectPeerId = [_peerIdArr objectAtIndex:indexPath.row];
    if (self.choos) {
        self.choos(selectPeerId);
    }
    [self removeFromSuperview];
}


- (void)dealloc
{
    NSLog(@"JoinRoomFoundView----dealloc");

    _peerIdArr = nil;;
    [_mainTabelView removeFromSuperview];
    _mainTabelView = nil;
}

@end
