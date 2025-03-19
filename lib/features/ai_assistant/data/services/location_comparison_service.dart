import 'package:dart_openai/dart_openai.dart';
import '../../../../core/network/network_connectivity_service.dart';

class LocationComparisonService {
  OpenAI? _openAI;
  final NetworkConnectivityService _connectivityService = NetworkConnectivityService();
  
  Future<void> init() async {
    _openAI = OpenAI.instance;
  }
  
  Future<String> compareLocations(List<String> locations) async {
    if (_openAI == null) {
      throw Exception('LocationComparisonService has not been initialized');
    }
    
    if (locations.length < 2 || locations.length > 3) {
      throw Exception('You must provide 2 or 3 locations to compare');
    }
    
    try {
      // İnternet bağlantısını kontrol et
      if (!_connectivityService.isConnected.value) {
        throw Exception('İnternet bağlantısı bulunamadı. Lütfen bağlantınızı kontrol edin ve tekrar deneyin.');
      }
      
      // Karşılaştırma promptunu oluştur
      final prompt = _buildComparisonPrompt(locations);
      
      // OpenAI API'ye istek gönder
      final completion = await _openAI!.chat.create(
        model: "gpt-4o-mini-2024-07-18",
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                '''System Instructions: Location Comparison AI Assistant

Role and Overall Approach:
You are an advanced AI consultant specializing in comparing different locations for people who are considering relocation.
Your goal is to provide a comprehensive, objective comparison between the locations provided by the user.
Your analysis should be structured, detailed, and easy to understand.

Comparison Framework:
When comparing locations, analyze and compare them across the following key categories:
1. Living Space and Home Features: Size of homes, number of rooms, land/garden area.
2. Cost of Living: Housing prices/rent, utilities, food, healthcare expenses, and other monthly costs.
3. Job Opportunities: Local job market, industries, average salaries, commute times.
4. Education: Names of nearby schools, academic achievement rates, suitability for children.
5. Shopping and Daily Needs: Grocery stores, shopping centers, ease of access.
6. Sports: Sports facilities, parks, outdoor activities.
7. Transportation: Public transit options, traffic conditions, distance to major cities.
8. Safety: Crime rates, neighborhood security.
9. Climate: Weather conditions and their impact on daily life.
10. Community and Lifestyle: Family-friendly environment, cultural diversity, local events.

Response Format:
- Begin with a brief introduction of the locations being compared
- For each category, create a section with a clear heading (use markdown ## for category headings)
- Under each category heading, provide a detailed comparison of all locations with specific details
- Include specific examples like school names, shopping centers, etc. when possible
- Use a rating system (1-10) for each category and clearly state the rating for each location
- Highlight the strengths and weaknesses of each location
- Use markdown formatting for better readability:
  * Use ## for category headings
  * Use ### for location names within categories
  * Use **bold** for important points
  * Use bullet points (- ) for listing features
  * Use > for highlighting key insights
- IMPORTANT: Always include a "## Summary of Ratings" section with a markdown table showing all categories and ratings for each location
- The ratings table must include all 10 categories with a score (1-10) for each location
- Conclude with a "## Recommendation" section that identifies which location might be best overall

Additional Guidelines:
- Be objective and balanced in your assessment
- Provide specific, named examples for facilities, schools, shopping centers, etc.
- Use the most current data available (assume current date is March 3, 2025)
- Provide practical insights that would be valuable for someone considering moving to these locations
- Keep your comparison factual and avoid subjective opinions unless specifically requested
- Write your response in English
- Use markdown formatting consistently throughout your response
- Make sure your response is well-structured and easy to read''',
              ),
            ],
            role: OpenAIChatMessageRole.system,
          ),
          OpenAIChatCompletionChoiceMessageModel(
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
            ],
            role: OpenAIChatMessageRole.user,
          ),
        ],
      );
      
      if (completion.choices.isNotEmpty) {
        final response = completion.choices.first.message;
        final responseText = response.content?.first.text;
        
        if (responseText != null) {
          return responseText;
        } else {
          throw Exception('AI response is empty');
        }
      } else {
        throw Exception('No response from AI');
      }
    } catch (e) {
      throw Exception('Failed to compare locations: $e');
    }
  }
  
  String _buildComparisonPrompt(List<String> locations) {
    final locationsList = locations.map((loc) => "- $loc").join("\n");
    
    return '''
I would like a detailed comparison of the following locations: 

$locationsList

Please consider the following parameters and variables in your comparison:

- Living Space and Home Features: Size of homes, number of rooms, land/garden area.
- Cost of Living: Housing prices/rent, utilities, food, healthcare expenses, and other monthly costs.
- Job Opportunities: Local job market, industries, average salaries, commute times.
- Education: Names of nearby schools, academic achievement rates, suitability for children.
- Shopping and Daily Needs: Grocery stores, shopping centers, ease of access.
- Sports: Sports facilities, parks, outdoor activities.
- Transportation: Public transit options, traffic conditions, distance to major cities.
- Safety: Crime rates, neighborhood security.
- Climate: Weather conditions and their impact on daily life.
- Community and Lifestyle: Family-friendly environment, cultural diversity, local events.

When conducting your analysis:  
- Provide detailed information for each parameter (e.g., school names, shopping center names, types of sports facilities).
- Use a rating system (1-10) for each category to make comparisons clearer.
- Use markdown formatting to make your response well-structured and easy to read.
- IMPORTANT: Include a "Summary of Ratings" section with a markdown table showing all categories and ratings for each location.
- The ratings table must include all 10 categories with a score (1-10) for each location.
- Conclude with a recommendation for which option would be more suitable overall.  

Current date: March 3, 2025. Please ensure that your information is as current and accurate as possible.
''';
  }
} 