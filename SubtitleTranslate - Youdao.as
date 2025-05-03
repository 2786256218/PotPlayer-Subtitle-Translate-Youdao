/*
	real time subtitle translate for PotPlayer using Youdao API
	https://ai.youdao.com/
*/

// void OnInitialize()
// void OnFinalize()
// string GetTitle() 									-> get title for UI
// string GetVersion									-> get version for manage
// string GetDesc()										-> get detail information
// string GetLoginTitle()								-> get title for login dialog
// string GetLoginDesc()								-> get desc for login dialog
// string GetUserText()									-> get user text for login dialog
// string GetPasswordText()								-> get password text for login dialog
// string ServerLogin(string User, string Pass)					-> login
// string ServerLogout()								-> logout
//------------------------------------------------------------------------------------------------
// array<string> GetSrcLangs() 								-> get source language
// array<string> GetDstLangs() 								-> get target language
// string Translate(string Text, string &in SrcLang, string &in DstLang) 	-> do translate !!

// 配置参数
string UserAgent = "Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari";
int coolTime = 1000; // 冷却时间(毫秒)
int nextExecuteTime = 0; // 下次执行时间

// API凭证
string api_id;
string api_key;

string JsonParse(string json)
{
	JsonReader Reader;
	JsonValue Root;
	string ret = "";	
	
	if (Reader.parse(json, Root) && Root.isObject())
	{
		JsonValue translation = Root["translation"];
		
		if (translation.isArray())
		{
			for (int i = 0, len = translation.size(); i < len; i++)
			{
				JsonValue translatedText = translation[i];
				
				if (!ret.empty()) ret = ret + "\n";
				if (translatedText.isString()) ret = ret + translatedText.asString();
			}
		}
	} 
	return ret;
}

array<string> LangTable = 
{
	"zh-CHS",
	"en",
	"ja",
	"ko",
	"fr",
	"ru",
	"pt",
	"es",
	"vi",
	"de",
	"ar"
};

string GetTitle()
{
	return "{$CP949=유도 번역$}{$CP950=有道翻譯$}{$CP0=Youdao translate$}";
}

string GetVersion()
{
	return "2";
}

string GetDesc()
{
	return "<a href=\"https://ai.youdao.com/\">https://ai.youdao.com/</a>";
}

string GetLoginTitle()
{
	return "请输入有道智云API配置";
}

string GetLoginDesc()
{
	return "请输入应用ID和应用密钥";
}

string GetUserText()
{
	return "应用ID:";
}

string GetPasswordText()
{
	return "应用密钥:";
}

string ServerLogin(string User, string Pass)
{
	api_id = User;
	api_key = Pass;
	if (api_id.empty() || api_key.empty()) return "fail";
	return "200 ok";
}

void ServerLogout()
{
	api_id = "";
	api_key = "";
}

array<string> GetSrcLangs()
{
	array<string> ret = LangTable;
	
	ret.insertAt(0, ""); // empty is auto
	return ret;
}

array<string> GetDstLangs()
{
	array<string> ret = LangTable;
	
	return ret;
}

string Translate(string Text, string &in SrcLang, string &in DstLang)
{
	string ret = "";
	if (!Text.empty())
	{
		//HostOpenConsole();	// for debug
		
		if (SrcLang.length() <= 0) SrcLang = "auto";
		SrcLang.MakeLower();
		
		string enc = HostUrlEncode(Text);
		
		if (api_id.length() > 0 && api_key.length() > 0)
		{
			// 计算冷却时间
			int tickCount = HostGetTickCount();
			int sleepTime = nextExecuteTime - tickCount;
			if (sleepTime > 0)
			{
				HostSleep(sleepTime);
			}

			// 构建API请求
			string salt = "" + HostGetTickCount();
			string sign = HostHashMD5(api_id + Text + salt + api_key);
			string url = "https://openapi.youdao.com/api?appKey=" + api_id + 
						"&q=" + enc + 
						"&from=" + SrcLang + 
						"&to=" + DstLang + 
						"&salt=" + salt + 
						"&sign=" + sign;
			
			string text = HostUrlGetString(url, UserAgent);
			ret = JsonParse(text);
			
			// 更新下次执行时间
			nextExecuteTime = coolTime + HostGetTickCount();
			
			if (ret.length() > 0)
			{
				SrcLang = "UTF8";
				DstLang = "UTF8";
			}

			// 如果翻译结果与原文相同，返回空格
			if (Text == ret)
			{
				ret = " ";
			}
		}
	}
	
	return ret;
}