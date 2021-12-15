'use strict';
var vscode_1 = require("vscode");
var coffeeScriptPreviewContentProvider_1 = require("./cs-preview/coffeeScriptPreviewContentProvider");
var coffeeScriptPreview_1 = require("./cs-preview/coffeeScriptPreview");
var workspaceService_1 = require("./vscode/workspaceService");
var windowService_1 = require("./vscode/windowService");
function activate(context) {
    var windowService = new windowService_1.WindowService();
    var workspaceService = new workspaceService_1.WorkspaceService();
    var provider = new coffeeScriptPreviewContentProvider_1.CoffeeScriptPreviewContentProvider(windowService);
    var csPreview = new coffeeScriptPreview_1.CoffeeScriptPreview(provider, workspaceService, windowService);
    var providerRegistration = vscode_1.workspace.registerTextDocumentContentProvider("coffeescript-preview", provider);
    var commandRegistration = vscode_1.commands.registerCommand("extension.coffeescript-preview", csPreview.previewDocument, csPreview);
    var pluginStartup = csPreview.start();
    context.subscriptions.push(commandRegistration, providerRegistration, pluginStartup);
}
exports.activate = activate;
//# sourceMappingURL=extension.js.map