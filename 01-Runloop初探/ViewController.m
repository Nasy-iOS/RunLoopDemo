//
//  ViewController.m
//  runloop简介
//
//  Created by Nasy on 2020/5/23.
//  Copyright © 2020 nasy. All rights reserved.
//

#import "ViewController.h"
#import "YNThread.h"
#import <objc/message.h>

@interface ViewController ()<UIScrollViewDelegate,UITextViewDelegate,NSPortDelegate>
{
    BOOL  isStop;
}
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic, strong) NSPort* subThreadPort;
@property (nonatomic, strong) NSPort* mainThreadPort;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textView.delegate = self;
    //Runloop与线程
//    [self runloopAndThread];
    //NSTimer f定时器调用
//    [self timerDemo];
    //CFRunLoopTimerRef 定时器
//    [self CFRunLoopTimerRefDemo];
    //cfObseverDemo 观察者
//    [self cfObseverDemo];
    //source0Demo
//    [self source0Demo];
    //port用于线程间通信
    [self portSendMessage];
    
    // Do any additional setup after loading the view.
}


#pragma mark - Runloop与线程

- (void)runloopAndThread{
    // 线程----->runloop ----> 定时器
    YNThread *thread = [[YNThread alloc]initWithBlock:^{
        [NSTimer scheduledTimerWithTimeInterval:2 repeats:YES block:^(NSTimer * _Nonnull timer) {
            NSLog(@"%@子线程内部的定时器%@",[YNThread currentThread].name,timer);
            if (self->isStop) {
                [YNThread exit];// 退出线程--结果runloop也停止了
            }
        }];
        NSLog(@"%d",CFRunLoopGetCurrent()==CFRunLoopGetMain());
        NSLog(@"%@===%@",CFRunLoopGetMain(),[NSRunLoop mainRunLoop]);
        NSLog(@"%@===%@",CFRunLoopGetCurrent(),[NSRunLoop currentRunLoop]);
        [[NSRunLoop currentRunLoop] run];
        //比较当前runloop与主运行循环
        
    }];
    thread.name = @"yinen.iOS.com";
    [thread start];
}


#pragma mark - NSTimer demo

- (void)timerDemo{
    
    // CFRunLoopMode 研究
    CFRunLoopRef lp     = CFRunLoopGetCurrent();
    CFRunLoopMode mode  = CFRunLoopCopyCurrentMode(lp);
    NSLog(@"mode == %@",mode);
    CFArrayRef modeArray= CFRunLoopCopyAllModes(lp);
    NSLog(@"modeArray == %@",modeArray);
    NSTimer *timer = [NSTimer timerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        NSLog(@"fire in home -- %@",[[NSRunLoop currentRunLoop] currentMode]);
        
    }];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

#pragma mark - CFRunLoopTimerRef 定时器
- (void)CFRunLoopTimerRefDemo {
    CFRunLoopTimerContext timerContext = {
        0,
        ((__bridge void *)self),
        NULL,
        NULL,
        NULL
    };
    /**
    参数一:用于分配对象的内存
    参数二:在什么是触发 (距离现在)
    参数三:每隔多少时间触发一次
    参数四:未来参数
    参数五:CFRunLoopObserver的优先级 当在Runloop同一运行阶段中有多个CFRunLoopObserver 正常情况下使用0
    参数六:回调,比如触发事件,我就会来到这里
    参数七:上下文记录信息
    */
    CFRunLoopTimerRef timerRef = CFRunLoopTimerCreate(CFAllocatorGetDefault(), 0, 2, 0, 0, RunLoopTimerCallBack , &timerContext);
    CFRunLoopAddTimer(CFRunLoopGetCurrent(), timerRef, kCFRunLoopDefaultMode);
}

void RunLoopTimerCallBack(CFRunLoopTimerRef timer, void *info) {
    NSLog(@"%@---%@",timer,info);
}


#pragma mark - observe

- (void)cfObseverDemo{
    
    CFRunLoopObserverContext context = {
        0,
        ((__bridge void *)self),
        NULL,
        NULL,
        NULL
    };
    CFRunLoopRef rlp = CFRunLoopGetCurrent();
    /**
     参数一:用于分配对象的内存
     参数二:你关注的事件
          kCFRunLoopEntry=(1<<0),
          kCFRunLoopBeforeTimers=(1<<1),
          kCFRunLoopBeforeSources=(1<<2),
          kCFRunLoopBeforeWaiting=(1<<5),
          kCFRunLoopAfterWaiting=(1<<6),
          kCFRunLoopExit=(1<<7),
          kCFRunLoopAllActivities=0x0FFFFFFFU
     参数三:CFRunLoopObserver是否循环调用
     参数四:CFRunLoopObserver的优先级 当在Runloop同一运行阶段中有多个CFRunLoopObserver 正常情况下使用0
     参数五:回调,比如触发事件,我就会来到这里
     参数六:上下文记录信息
     */
//    CFRunLoopObserverRef observerRef = CFRunLoopObserverCreateWithHandler(CFAllocatorGetDefault(), kCFRunLoopAllActivities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
//        NSLog(@"%lu-%@",activity,observer);
//    });
    CFRunLoopObserverRef observerRef = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, lgRunLoopObserverCallBack, &context);
    CFRunLoopAddObserver(rlp, observerRef, kCFRunLoopDefaultMode);
}

void lgRunLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    NSLog(@"%lu-%@",activity,info);
}



#pragma mark - source0:演练

// 就是喜欢玩一下: 我们下面来自定义一个source
- (void)source0Demo{
    
    CFRunLoopSourceContext context = {
        0,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        schedule,
        cancel,
        perform,
    };
    /**
     
     参数一:传递NULL或kCFAllocatorDefault以使用当前默认分配器。
     参数二:优先级索引，指示处理运行循环源的顺序。这里我传0为了的就是自主回调
     参数三:为运行循环源保存上下文信息的结构
     */
    CFRunLoopSourceRef source0 = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &context);
    CFRunLoopRef rlp = CFRunLoopGetCurrent();
    // source --> runloop 指定了mode  那么此时我们source就进入待绪状态
    CFRunLoopAddSource(rlp, source0, kCFRunLoopDefaultMode);
    // 一个执行信号
    CFRunLoopSourceSignal(source0);
    // 唤醒 run loop 防止沉睡状态
    CFRunLoopWakeUp(rlp);
    // 取消 移除
//    CFRunLoopRemoveSource(rlp, source0, kCFRunLoopDefaultMode);
    CFRelease(rlp);
}

void schedule(void *info, CFRunLoopRef rl, CFRunLoopMode mode){
    NSLog(@"准备代发");
}

void perform(void *info){
    NSLog(@"执行吧,骚年");
}

void cancel(void *info, CFRunLoopRef rl, CFRunLoopMode mode){
    NSLog(@"取消了,终止了!!!!");
}
#pragma mark - source1 利用port的线程间通信

- (void)portSendMessage {
    self.mainThreadPort = [NSPort port];
    self.mainThreadPort.delegate = self;
    [[NSRunLoop currentRunLoop] addPort:self.mainThreadPort forMode:NSDefaultRunLoopMode];
    
    YNThread *thread = [[YNThread alloc] initWithBlock:^{
        self.subThreadPort = [NSPort port];
        self.subThreadPort.delegate = self;
        [[NSRunLoop currentRunLoop] addPort:self.subThreadPort forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] run];
    }];
    [thread start];
}


- (void)handlePortMessage:(id)message{
    NSLog(@"%@----%@",message,[NSThread currentThread]);
    unsigned int count = 0;
    Ivar *ivars = class_copyIvarList([message class], &count);
    for (int i = 0; i<count; i++) {
        NSString *name = [NSString stringWithUTF8String:ivar_getName(ivars[i])];
        NSLog(@"%@",name);
        if ([name isEqualToString:@"components"]) {
            NSMutableArray *components =[message valueForKey:name];
            NSMutableArray *strArr = [NSMutableArray array];
            for (int i = 0; i < components.count; i ++) {
                NSString *eleStr = [[NSString alloc]initWithData:components[i] encoding:NSUTF8StringEncoding];
                [strArr addObject:eleStr];
            }
            NSLog(@"%@",[strArr componentsJoinedByString:@" "]);
            if (![[NSThread currentThread] isMainThread]) {
                [self mainThreadSendMessageWithString:[strArr componentsJoinedByString:@" "]];
            }
        }
    }
}

- (void)subThreadSendMessage{
    NSMutableArray* components = [NSMutableArray array];
    NSString *str = @"Helllo World";
    NSArray *strArr = [str componentsSeparatedByString:@" "];
    for (int i = 0; i < strArr.count; i ++) {
        NSData* data = [strArr[i] dataUsingEncoding:NSUTF8StringEncoding];
        [components addObject:data];
    }
    [self.subThreadPort sendBeforeDate:[NSDate date] msgid:1009 components:components from:self.mainThreadPort reserved:0];
}
- (void)mainThreadSendMessageWithString:(NSString *)str {
    NSMutableArray* components = [NSMutableArray array];
    NSData* data = [[NSString stringWithFormat:@"%@,I'm comming!",str] dataUsingEncoding:NSUTF8StringEncoding];
    [components addObject:data];
    [self.mainThreadPort sendBeforeDate:[NSDate date] components:components from:self.subThreadPort reserved:0];
}



#pragma mark -UIScrollViewDelegate &&superMethods
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView{
    NSLog(@"runloopMode------%@",[NSRunLoop currentRunLoop].currentMode);
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    isStop = YES;
    [self subThreadSendMessage];
}

@end
