//
//  ViewController.m
//  ConnectivityDemo
//
//  Created by ZhuJunyu on 16/8/9.
//  Copyright © 2016年 ZhuJunyu. All rights reserved.
//

#import "ViewController.h"
#import "JoinRoomFoundView.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h> //导入框架头文件

/*
 大概实现过程
   A设备创建一个服务端－>b搜索附近服务－>搜索到侯发出请求加入－>a同意加入－>双方通过MCSession进行对话
    －>对话完后可以关闭服务 b也可以主动断开（服务关闭后b会有回调通知，然后记得关掉搜索通知）－>结束
 */


@interface ViewController ()<MCSessionDelegate,MCNearbyServiceAdvertiserDelegate,MCNearbyServiceBrowserDelegate,UIAlertViewDelegate>
{
    MCSession                   * _session; //会话对象
    NSString                    * _serviceType;//服务标示符 自定义
    MCNearbyServiceAdvertiser   * _nearAdvertiser;//服务端对象
    MCNearbyServiceBrowser      * _nearBrowser;//搜索对象
    NSMutableArray              *_peerArr;//连接上的设备数组
    void (^_isAllowJoinBlock)(BOOL, MCSession * _Nonnull); //授权加入回调
    UITextView                  *_textView;
}
@end

@implementation ViewController

#pragma mark-lifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    _serviceType = @"blue-stream";
    _peerArr = [NSMutableArray new];
    [self configView];
      // Do any additional setup after loading the view, typically from a nib.
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark-UIHelper
- (void)configView{
    float btnWidth = 100;
    UIButton *creatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    creatBtn.frame = CGRectMake(10, 44, btnWidth, 40);
    [creatBtn setTitle:@"创建" forState:UIControlStateNormal];
    creatBtn.backgroundColor = [UIColor redColor];
    [creatBtn addTarget:self action:@selector(creatSession) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:creatBtn];
    
    UIButton *stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    stopBtn.frame = CGRectMake(btnWidth+30, 44, btnWidth, 40);
    [stopBtn setTitle:@"断开" forState:UIControlStateNormal];
    stopBtn.backgroundColor = [UIColor redColor];
    [stopBtn addTarget:self action:@selector(stopSession) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:stopBtn];
    
    UIButton *searchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    searchBtn.frame = CGRectMake(10, 100, btnWidth, 40);
    [searchBtn setTitle:@"搜索" forState:UIControlStateNormal];
    searchBtn.backgroundColor = [UIColor blackColor];
    [searchBtn addTarget:self action:@selector(goJoinWaiting) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:searchBtn];
    
    UIButton *sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    sendBtn.frame = CGRectMake(10, 160, btnWidth, 40);
    [sendBtn setTitle:@"发送" forState:UIControlStateNormal];
    sendBtn.backgroundColor = [UIColor blackColor];
    [sendBtn addTarget:self action:@selector(sendHandler) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sendBtn];
    
    _textView = [[UITextView alloc] initWithFrame:CGRectMake(20, 210, 300, 270)];
    [self.view addSubview:_textView];

}


#pragma mark-MCNearbyServiceBrowserDelegate
//发现服务端
- (void)        browser:(MCNearbyServiceBrowser *)browser
              foundPeer:(MCPeerID *)peerID
      withDiscoveryInfo:(nullable NSDictionary<NSString *, NSString *> *)info{

    JoinRoomFoundView *view = [[JoinRoomFoundView alloc] initWithFrame:self.view.bounds];
    view.choos = ^(MCPeerID *ID){
        _textView.text = [_textView.text stringByAppendingFormat:@"\n%@",peerID.displayName];
        [_nearBrowser invitePeer:ID toSession:_session withContext:nil timeout:10.0]; //加入时等待主持人允许，10秒后不答应就退出
    };
    [view addPeerIdAndReload:peerID];
    [self.view addSubview:view];
}

// A nearby peer has stopped advertising. 服务丢失
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID{
    [self stopSession];
    [self showMessage:@"服务丢失"];
}
#pragma mark--MCSessionDelegate
// Remote peer changed state. 设备连接状态改变
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    switch (state) {
        case MCSessionStateConnecting:
        {
            [self showMessage:[NSString stringWithFormat:@"%@ 真在连接",peerID.displayName]];
        }break;
        case MCSessionStateConnected:
        {
            
            [_peerArr addObject:peerID];
            [self showMessage:[NSString stringWithFormat:@"%@ 链接上了",peerID.displayName]];
        }break;
        case MCSessionStateNotConnected:
        {
            [self showMessage:[NSString stringWithFormat:@"%@ 失去连接",peerID.displayName]];
            [_peerArr removeObject:peerID];
            
        }break;
            
        default:
            break;
    }
}

// Received data from remote peer. 收到消息
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    NSString *aString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"收=========%@",aString);
    dispatch_async(dispatch_get_main_queue(), ^{
        _textView.text = [_textView.text stringByAppendingFormat:@"\n%@",aString];
    });
}

// Received a byte stream from remote peer. 收到文件流
- (void)    session:(MCSession *)session
   didReceiveStream:(NSInputStream *)stream
           withName:(NSString *)streamName
           fromPeer:(MCPeerID *)peerID{
    
}

// Start receiving a resource from remote peer. 开始接受文件
- (void)                    session:(MCSession *)session
  didStartReceivingResourceWithName:(NSString *)resourceName
                           fromPeer:(MCPeerID *)peerID
                       withProgress:(NSProgress *)progress{
    
}

// Finished receiving a resource from remote peer and saved the content
// in a temporary location - the app is responsible for moving the file
// to a permanent location within its sandbox. 文件接受完毕
- (void)                    session:(MCSession *)session
 didFinishReceivingResourceWithName:(NSString *)resourceName
                           fromPeer:(MCPeerID *)peerID
                              atURL:(NSURL *)localURL
                          withError:(nullable NSError *)error{
    
}


#pragma mark-MCNearbyServiceAdvertiserDelegate
//收到加入请求
- (void)            advertiser:(MCNearbyServiceAdvertiser *)advertiser
  didReceiveInvitationFromPeer:(MCPeerID *)peerID
                   withContext:(nullable NSData *)context
             invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler{

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:@"%@ 申请加入.是否允许？",peerID.displayName] delegate:self cancelButtonTitle:@"否" otherButtonTitles:@"是", nil];
    [alert show];
    _isAllowJoinBlock = invitationHandler;
    _textView.text = [_textView.text stringByAppendingFormat:@"\n%@",peerID.displayName];

}
#pragma mark-UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex) {
        _isAllowJoinBlock(YES,_session);
        [self showMessage:@"同意加入"];
    }
}
#pragma mark-BtnAction
- (void)stopSession{
    [_session  disconnect];
    [_nearAdvertiser stopAdvertisingPeer];
    [_nearBrowser stopBrowsingForPeers];
    _session= nil;
    _nearBrowser = nil;
    _nearAdvertiser = nil;
    [self showMessage:@"断开服务"];

}
//通过session向同一个服务中的所有设备发送消息
-(void)sendHandler
{
    NSString *dateString = @"hello";
    NSData * aData = [dateString dataUsingEncoding: NSUTF8StringEncoding];
    NSError * error = nil;
    [_session sendData:aData toPeers:_peerArr withMode:MCSessionSendDataReliable error:&error];
    NSLog(@"开始发送数据.....");
    
    if(error)
    {
        [self showMessage:[NSString stringWithFormat:@"发送失败======%@",error]];
    }
}
//查找附近服务
-(void)goJoinWaiting
{
    MCPeerID * peerID = [[MCPeerID alloc]initWithDisplayName:[[UIDevice currentDevice] name]];
    if(_session==nil)
    {
        _session = [[MCSession alloc]initWithPeer:peerID];
        _session.delegate = self;
    }
    if(_nearAdvertiser==nil)
    {
        _nearBrowser = [[MCNearbyServiceBrowser alloc]initWithPeer:peerID serviceType:_serviceType];
        _nearBrowser.delegate = self;
        [_nearBrowser startBrowsingForPeers];
        [self showMessage:@"开始搜索房间......"];
    }
}
//创建服务
- (void)creatSession{
    MCPeerID * peerID = [[MCPeerID alloc]initWithDisplayName:[[UIDevice currentDevice] name]];
    if(_session==nil)
    {
        _session = [[MCSession alloc]initWithPeer:peerID];
        _session.delegate = self;
    }
    if(_nearAdvertiser==nil)
    {
        _nearAdvertiser = [[MCNearbyServiceAdvertiser alloc]initWithPeer:peerID discoveryInfo:nil serviceType:_serviceType];
        _nearAdvertiser.delegate = self;
        [_nearAdvertiser startAdvertisingPeer];         //开始发布广播
        [self showMessage:@"新建房间，开始广播....."];
    }
}

- (void)showMessage:(NSString *)message{
    dispatch_async(dispatch_get_main_queue(), ^{
        _textView.text = [_textView.text stringByAppendingFormat:@"\n%@",message];
    });

}

@end
