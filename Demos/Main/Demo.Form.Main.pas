{******************************************************************************}
{                                                                              }
{  Delphi GraphQL                                                              }
{  Copyright (c) 2022 Luca Minuti                                              }
{  https://github.com/lminuti/graphql                                          }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}
unit Demo.Form.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.IOUtils, System.Types, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  GraphQL.Core, GraphQL.Lexer.Core, GraphQL.SyntaxAnalysis.Builder, Vcl.ExtCtrls;

type
  TMainForm = class(TForm)
    SourceMemo: TMemo;
    LogMemo: TMemo;
    TreeBuilderButton: TButton;
    SyntaxTreeView: TTreeView;
    FilesComboBox: TComboBox;
    Label1: TLabel;
    Panel1: TPanel;
    Label2: TLabel;
    Label3: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure TreeBuilderButtonClick(Sender: TObject);
    procedure FilesComboBoxChange(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FSampleDir: string;
    procedure HandleReadToken(ASender: TObject; AToken: TToken);
    procedure ShowGraphQL(AGraphQL: IGraphQL);
    procedure ReadFiles;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  ReadFiles;
end;

procedure TMainForm.ReadFiles;
var
  LFiles: TStringDynArray;
  LFileName: string;
begin
  FSampleDir := ExtractFileDir( ParamStr(0)) + PathDelim + '..' + PathDelim + '..' + PathDelim + '..' + PathDelim + 'Files';

  FilesComboBox.Items.Clear;
  LFiles := TDirectory.GetFiles(FSampleDir);
  for LFileName in LFiles do
    FilesComboBox.Items.Add(ExtractFileName(LFileName));
end;

procedure TMainForm.TreeBuilderButtonClick(Sender: TObject);
var
  LBuilder: TGraphQLBuilder;
  LGraphQL: IGraphQL;
begin
  inherited;
  if SourceMemo.Text = '' then
    Exit;

  SyntaxTreeView.Items.Clear;
  LogMemo.Clear;

  LBuilder := TGraphQLBuilder.Create(SourceMemo.Text);
  try
    LBuilder.OnReadToken := HandleReadToken;
    LGraphQL := LBuilder.Build;
  finally
    LBuilder.Free;
  end;

  ShowGraphQL(LGraphQL);

end;

procedure TMainForm.FilesComboBoxChange(Sender: TObject);
var
  LFileName: string;
begin
  if FilesComboBox.Text <> '' then
  begin
    LFileName := FSampleDir + PathDelim + FilesComboBox.Text;
    if FileExists(LFileName) then
      SourceMemo.Lines.LoadFromFile(LFileName);
  end;
end;

procedure TMainForm.FormKeyUp(Sender: TObject; var Key: Word; Shift:
    TShiftState);
begin
  if Key = VK_F5 then
    TreeBuilderButton.Click;
end;

procedure TMainForm.HandleReadToken(ASender: TObject; AToken: TToken);
begin
  LogMemo.Lines.Add(AToken.ToString);
end;

procedure TMainForm.ShowGraphQL(AGraphQL: IGraphQL);

  function GetFieldNameCaption(AGraphQLField: IGraphQLField): string;
  begin
    if AGraphQLField.FieldName = AGraphQLField.FieldAlias then
      Result := AGraphQLField.FieldName
    else
      Result := Format('%s (%s)', [AGraphQLField.FieldName, AGraphQLField.FieldAlias])
  end;

  procedure ShowArguments(LGraphQLField: IGraphQLField; AParentNode: TTreeNode);
  var
    LArgumentsNode: TTreeNode;
    LArgumentIndex: Integer;
    LGraphQLArgument: IGraphQLArgument;
  begin
    if LGraphQLField.ArgumentCount > 0 then
    begin
      LArgumentsNode := SyntaxTreeView.Items.AddChild(AParentNode, 'Arguments');
      for LArgumentIndex := 0 to LGraphQLField.ArgumentCount - 1 do
      begin
        LGraphQLArgument := LGraphQLField.Arguments[LArgumentIndex];
        SyntaxTreeView.Items.AddChild(LArgumentsNode, Format('%s : %s', [LGraphQLArgument.Name, LGraphQLArgument.Value.ToString]));
      end;
    end;
  end;

  procedure ShowObject(AGraphQLObject: IGraphQLObject; AParentNode: TTreeNode);
  var
    LSubNode: TTreeNode;
    LFieldIndex: Integer;
    LGraphQLField: IGraphQLField;
  begin
    for LFieldIndex := 0 to AGraphQLObject.FieldCount - 1 do
    begin
      LGraphQLField := AGraphQLObject.Fields[LFieldIndex];
      LSubNode := SyntaxTreeView.Items.AddChild(AParentNode, GetFieldNameCaption(LGraphQLField));
      ShowArguments(LGraphQLField, LSubNode);
      if Supports(LGraphQLField.Value, IGraphQLObject) then
      begin
        ShowObject(LGraphQLField.Value as IGraphQLObject, LSubNode);
      end;
    end;
  end;

var
  LRootNode, LSubNode: TTreeNode;
  LFieldIndex: Integer;
  LGraphQLField: IGraphQLField;
begin
  LRootNode := SyntaxTreeView.Items.AddChildFirst(nil, AGraphQL.Name + ' (query)');

  for LFieldIndex := 0 to AGraphQL.FieldCount - 1 do
  begin
    LGraphQLField := AGraphQL.Fields[LFieldIndex];
    LSubNode := SyntaxTreeView.Items.AddChild(LRootNode, GetFieldNameCaption(LGraphQLField));
    ShowArguments(LGraphQLField, LSubNode);
    if Supports(LGraphQLField.Value, IGraphQLObject) then
    begin
      ShowObject(LGraphQLField.Value as IGraphQLObject, LSubNode);
    end;

  end;

  LRootNode.Expand(True);

end;

end.
