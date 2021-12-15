'use strict';
var vscode_1 = require("vscode");
var WorkspaceService = (function () {
    function WorkspaceService() {
    }
    WorkspaceService.prototype.registerOnDocumentChangeListener = function (func) {
        return vscode_1.workspace.onDidChangeTextDocument(func);
    };
    WorkspaceService.prototype.openTextDocument = function (uri) {
        return vscode_1.workspace.openTextDocument(uri);
    };
    return WorkspaceService;
}());
exports.WorkspaceService = WorkspaceService;
//# sourceMappingURL=workspaceService.js.map