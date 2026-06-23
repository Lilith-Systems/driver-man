module MSN.CryptoWallet

@wrapMethod(PlayerPuppet)
protected cb func OnAction(action: ref<Action>, consumer: ref<ActionConsumer>) -> Bool {
    let actionName: CName = ListenerAction.GetName(action);
    let actionType: gameinputActionType = ListenerAction.GetType(action);

    // "Vision" is the action name for toggling the scanner / focus mode in Cyberpunk 2077
    if Equals(actionName, n"Vision") && Equals(actionType, gameinputActionType.BUTTON_PRESSED) {
        this.ShowAbyssalBalanceNotification();
    }
    
    return wrappedMethod(action, consumer);
}

@addMethod(PlayerPuppet)
public func ShowAbyssalBalanceNotification() -> Void {
    let msg: SimpleScreenMessage;
    msg.isShown = true;
    msg.duration = 4.0;
    
    // In a full integration pipeline, this balance would be fetched by the Python daemon
    // over the MSN routing layer, and then pushed to REDscript via the local file watcher 
    // or WolvenKit REDmod hook.
    msg.message = "MSN SYNC | Abyssal Soul Coins: 14,302 ASC";
    
    let bbSystem: ref<BlackboardSystem> = GameInstance.GetBlackboardSystem(this.GetGame());
    let bb: ref<IBlackboard> = bbSystem.Get(GetAllBlackboardDefs().UI_Notifications);
    
    if IsDefined(bb) {
        bb.SetVariant(GetAllBlackboardDefs().UI_Notifications.OnscreenMessage, ToVariant(msg), true);
    }
}
