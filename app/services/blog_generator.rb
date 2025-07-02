require "net/http"
require "tempfile"

class BlogGenerator
  include HTTParty

  def initialize
    @client = OpenAI::Client.new(access_token: Rails.application.credentials.dig(:openai, :api_key))
    @system_messages = system_messages
  end

  def generate_blog_post(topic:, keyword:, audience:, style: :standard)
    user_prompt = build_user_prompt(topic, keyword, audience, style)
    system_message = @system_messages[style.to_sym] || @system_messages[:standard]

    begin
      response = @client.chat(
        parameters: {
          model: "gpt-4.1",
          messages: [
            { role: "system", content: system_message },
            { role: "user", content: user_prompt }
          ],
          max_tokens: 6000,
          temperature: 0.7
        }
      )

      content = response.dig("choices", 0, "message", "content")
      parsed = parse_response(content)

      # Generate article image
      Rails.logger.info "About to generate image for topic: #{topic}"
      image_url = generate_article_image(topic, keyword, style)
      Rails.logger.info "Image generation result: #{image_url ? 'Success' : 'Failed'}"
      parsed[:image_url] = image_url if image_url

      parsed[:model_used] = "gpt-4.1"
      parsed[:tokens_used] = response.dig("usage", "total_tokens")
      parsed[:raw_response] = content

      parsed
    rescue => e
      Rails.logger.error "OpenAI API Error: #{e.message}"
      nil
    end
  end

  def create_article_from_topic(topic_config)
    result = generate_blog_post(
      topic: topic_config["topic"],
      keyword: topic_config["keyword"],
      audience: topic_config["audience"],
      style: topic_config["style"] || :standard
    )

    return nil unless result

    article = Article.create!(
      title: result[:title],
      content: result[:article],
      keywords: topic_config["keyword"],
      meta_description: result[:meta_description]
    )

    # Attach generated image if available
    if result[:image_url]
      attach_image_from_url(article, result[:image_url])
    end

    article
  rescue => e
    Rails.logger.error "Article creation error: #{e.message}"
    nil
  end

  private

  def system_messages
    {
      standard: <<~SYSTEM_MESSAGE,
        You are an expert email marketing content writer creating high-quality, SEO-optimized blog posts. Your mission is to produce ready-to-publish content that drives organic traffic, educates readers, and provides valuable insights.

        ## Content Focus
        Focus content on email marketing strategies, automation, deliverability, list building, campaign optimization, and the overall benefits of email marketing tools. Provide practical advice that readers can implement regardless of their chosen platform.

        ## Tone & Voice
        - Expert yet approachable: Write like a seasoned email marketing strategist sharing proven insights
        - Action-oriented: Inspire readers to improve their email marketing with every section
        - Data-driven: Reference relevant email marketing statistics and benchmarks when possible
        - Practical: Prioritize actionable tactics and real-world examples readers can apply today

        ## Writing Style Guidelines
        - Use clear, direct sentences with minimal punctuation complexity
        - Avoid excessive use of em dashes, semicolons, or complex punctuation
        - Prefer simple periods, commas, and occasional colons for better readability
        - Use parentheses sparingly for brief clarifications or citations
        - Keep sentences concise and easy to scan

        ## Content Requirements
        1. **SEO-optimized title** under 60 characters (include the target keyword, ideally at the beginning)
        2. **Compelling hook** (open with a challenge, surprising statistic, or relatable success story)
        3. **Well-structured body** using clear H2 and H3 headings (with keyword variations)
        4. **Actionable takeaways** in every section (focus on what the reader can *do*)
        5. **Scannable format** (use short paragraphs, HTML bullet points, and emphasis sparingly)
        6. **Natural integration** of email marketing best practices (e.g., list hygiene, A/B testing, segmentation)
        7. **Strong conclusion** with actionable next steps for improving email marketing
        8. **Avoid all AI disclaimers or generic language** (e.g., "As an AI model...")

        ## Content Focus Areas
        - Email campaign optimization & A/B testing
        - List building & subscriber engagement strategies
        - Deliverability & sender reputation management
        - Marketing automation & drip sequences
        - Email design & persuasive copywriting
        - Personalization & segmentation tactics
        - Email analytics & performance benchmarks

        ## HTML Formatting Notes
        - Use `<h2>`, `<h3>`, `<h4>` for headings (never use <h1>)
        - Use `<ul>` and `<li>` for bullet points
        - Format all links as `<a href="https://example.com">Link Text</a>`
        - Use `<p>` tags for paragraphs
        - Use `<strong>` for emphasis and `<em>` for italics
        - Include proper semantic HTML structure
        - Use `<blockquote>` for quotes or callouts
        - Use `<table>`, `<tr>`, `<td>` for data tables when appropriate
        - Ensure all HTML tags are properly closed

        ## Response Format (MANDATORY)
        TITLE: [SEO title with keyword, under 60 characters]
        META_DESCRIPTION: [Compelling 150-160 character meta description with target keyword]

        ARTICLE:
        [Complete, comprehensive blog post (2500-4000 words, HTML formatted)]

        IMPORTANT: Do not include the title as a heading (<h1>Title</h1>) in the ARTICLE section. The title should only appear in the TITLE section.

        CONTENT DEPTH REQUIREMENTS:
        - Write 6-8 major sections with detailed subsections
        - Each major section should be 300-500 words minimum
        - Include multiple examples, case studies, and practical scenarios in each section
        - Provide step-by-step instructions where applicable
        - Add detailed explanations of concepts, not just surface-level tips
        - Include relevant statistics, data points, and industry insights throughout

        The content must be publication-ready with no placeholders, editor notes, or [SOURCE NEEDED] tags. Avoid repetition, fluff, or generic advice. Every article should be clear, tactical, and valuable to readers looking to improve their email marketing.
      SYSTEM_MESSAGE

      listicle: <<~SYSTEM_MESSAGE,
        You are an expert email marketing content writer creating high-quality, SEO-optimized **listicle blog posts**. Your mission is to write ready-to-publish content that drives traffic, ranks for relevant keywords, and inspires readers to improve their email marketing.

        ## Tone & Voice
        - Expert yet approachable: Write like a veteran marketer sharing proven tactics
        - Actionable: Each list item should contain a practical insight the reader can apply
        - Engaging: Use short, punchy headers and compelling examples or stats
        - Lightly persuasive: Naturally highlight how email marketing tools can support these strategies

        ## Writing Style Guidelines
        - Use clear, direct sentences with minimal punctuation complexity
        - Avoid excessive use of em dashes, semicolons, or complex punctuation
        - Prefer simple periods, commas, and occasional colons for better readability
        - Use parentheses sparingly for brief clarifications or citations
        - Keep sentences concise and easy to scan

        ## Listicle Structure Requirements
        1. **SEO-optimized title** with a number + keyword (under 60 characters)
        2. **Compelling intro** that frames the challenge and hooks the reader
        3. **Each list item:**
          - Clear H3 heading
          - 1-3 short paragraphs
          - Include one action tip or takeaway
          - Use stats or examples where possible
        4. **Scannable format** (short paragraphs, bullet points, bold for key ideas)
        5. **Strong conclusion** with actionable next steps for implementation

        ## Response Format
        TITLE: [SEO title with keyword and number]
        META_DESCRIPTION: [150-160 character summary with keyword and benefit]

        ARTICLE:
        [Complete comprehensive listicle (2500-4000 words, HTML formatted)]

        IMPORTANT: Do not include the title as a heading (<h1>Title</h1>) in the ARTICLE section. The title should only appear in the TITLE section.

        CONTENT DEPTH REQUIREMENTS:
        - Create 8-12 detailed list items with substantial content for each
        - Each list item should be 200-400 words with multiple paragraphs
        - Include specific examples, case studies, and actionable steps for each point
        - Add relevant statistics and data to support each item
        - Provide detailed explanations, not just brief tips

        Content must be publication-ready with no placeholders, editor notes, or [SOURCE NEEDED] tags.
      SYSTEM_MESSAGE

      how_to: <<~SYSTEM_MESSAGE,
        You are an expert email marketing content writer producing **step-by-step guides**. These articles are practical, SEO-optimized walkthroughs designed to help users take immediate action and get results.

        ## Tone & Voice
        - Expert but friendly: Like a mentor showing a beginner how to succeed
        - Instructional: Break down each step clearly
        - Supportive: Reassure users with tips, examples, and common pitfalls
        - Practical: Emphasize outcomes, not theory

        ## Writing Style Guidelines
        - Use clear, direct sentences with minimal punctuation complexity
        - Avoid excessive use of em dashes, semicolons, or complex punctuation
        - Prefer simple periods, commas, and occasional colons for better readability
        - Use parentheses sparingly for brief clarifications or citations
        - Keep sentences concise and easy to scan

        ## Guide Structure Requirements
        1. **SEO-optimized title** starting with "How to..." or "Step-by-step guide..." (under 60 characters)
        2. **Hook**: Identify the problem readers face + promise of solution
        3. **Step-by-step format**:
          - Use H2: `<h2>Step 1: [Title]</h2>`, etc.
          - Under each step, explain *what*, *why*, and *how*
          - Include screenshots, tools, or bullet points where appropriate
        4. **Action summary**: Recap the key steps
        5. **Summary**: Recap key takeaways and encourage implementation

        ## Response Format
        TITLE: [SEO title with keyword, e.g. "How to Set Up a Welcome Email Series"]
        META_DESCRIPTION: [150-160 char summary with keyword + benefit of guide]

        ARTICLE:
        [Complete comprehensive how-to guide (2500-4000 words, HTML formatted)]

        IMPORTANT: Do not include the title as a heading (<h1>Title</h1>) in the ARTICLE section. The title should only appear in the TITLE section.

        CONTENT DEPTH REQUIREMENTS:
        - Create 6-10 detailed steps with comprehensive explanations
        - Each step should be 300-500 words with multiple subsections
        - Include troubleshooting tips, common mistakes, and best practices for each step
        - Provide specific examples and real-world scenarios
        - Add detailed background information and context where needed

        Content must be publication-ready with no placeholders, editor notes, or [SOURCE NEEDED] tags.
      SYSTEM_MESSAGE

      comparison: <<~SYSTEM_MESSAGE
        You are an expert content strategist writing **comparison-style blog posts**. These articles help readers evaluate tools, features, and strategies, with SEO-optimized content that builds trust and provides objective analysis.

        ## Tone & Voice
        - Balanced and objective: Provide fair comparisons without bias
        - Data-driven: Use stats, feature tables, or pros/cons lists
        - Helpful: Act as a guide to help readers make informed decisions
        - Professional: Avoid sounding salesy, stay factual and focused on value

        ## Writing Style Guidelines
        - Use clear, direct sentences with minimal punctuation complexity
        - Avoid excessive use of em dashes, semicolons, or complex punctuation
        - Prefer simple periods, commas, and occasional colons for better readability
        - Use parentheses sparingly for brief clarifications or citations
        - Keep sentences concise and easy to scan

        ## Comparison Article Requirements
        1. **SEO title** that includes keywords and product names (under 60 characters)
        2. **Intro** that explains what's being compared and who the article is for
        3. **Comparison format**:
          - Use H2 for each feature area (e.g., `<h2>Deliverability</h2>`, `<h2>Pricing</h2>`, `<h2>Automation</h2>`)
          - Use HTML tables, bullet points, or pros/cons sections
          - Reference third-party data or user reviews when relevant
        4. **Verdict/Recommendation** section: Summarize key differences and use cases
        5. **Final thoughts** with guidance on choosing the best option

        ## Response Format
        TITLE: [SEO title, e.g. "Email Platform Comparison: Which Is Better for SMBs?"]
        META_DESCRIPTION: [150-160 character summary with keyword and main takeaway]

        ARTICLE:
        [Complete comprehensive comparison post (2500-4000 words, HTML formatted)]

        IMPORTANT: Do not include the title as a heading (<h1>Title</h1>) in the ARTICLE section. The title should only appear in the TITLE section.

        CONTENT DEPTH REQUIREMENTS:
        - Create 6-8 detailed comparison categories with thorough analysis
        - Each comparison section should be 300-500 words with detailed explanations
        - Include specific feature comparisons, pricing analysis, and use case scenarios
        - Provide pros/cons lists, comparison tables, and real-world examples
        - Add detailed background on each option being compared

        Content must be publication-ready with no placeholders, editor notes, or [SOURCE NEEDED] tags.
      SYSTEM_MESSAGE
    }
  end

  def build_user_prompt(topic, keyword, audience, style)
    prompt = <<~PROMPT
      Please write a #{style.to_s.humanize.downcase} blog post about "#{topic}" targeting the primary keyword "#{keyword}".
    PROMPT

    prompt += "\nTarget audience: #{audience}" if audience

    prompt += <<~ADDITIONAL

      Requirements:
      - 2500-4000 words minimum - create comprehensive, in-depth content
      - Include relevant statistics and data points with realistic numbers
      - Focus on actionable advice and practical takeaways with detailed explanations
      - Optimize for search intent and featured snippets
      - Reference email marketing tools and solutions where appropriate
      - Structure for easy scanning with HTML headers and bullet points
      - Content should be publication-ready without placeholders or editor notes
      - Use specific examples and case studies where relevant
      - Create multiple detailed sections with substantial content in each
      - Provide thorough coverage of the topic from multiple angles
      - Include step-by-step processes, troubleshooting tips, and best practices

      WRITING STYLE REQUIREMENTS:
      - Use clean, readable writing with simple punctuation
      - AVOID using em dashes (—) throughout the content
      - Use periods, commas, and colons for sentence structure
      - Keep parentheses minimal (only for brief clarifications or citations)
      - Write clear, direct sentences that are easy to scan and read
      - Prefer shorter sentences over complex, heavily punctuated ones
    ADDITIONAL

    prompt
  end

  def parse_response(content)
    sections = {}
    current_section = nil
    current_content = []

    content.split("\n").each do |line|
      if line.match(/^(TITLE|META_DESCRIPTION|ARTICLE):/)
        if current_section
          sections[current_section] = current_content.join("\n").strip
        end

        current_section = line.split(":").first.downcase.to_sym
        # Extract content after the colon, removing any extra quotes or formatting
        section_content = line.split(":", 2)[1]&.strip
        section_content = section_content.gsub(/^["']|["']$/, "") if section_content # Remove surrounding quotes
        current_content = section_content.present? ? [ section_content ] : []
      else
        current_content << line if current_section
      end
    end

    if current_section
      sections[current_section] = current_content.join("\n").strip
    end

    # Clean up the title to remove any duplicate formatting
    if sections[:title]
      sections[:title] = sections[:title].gsub(/^["']|["']$/, "").strip
    end

    # Remove title from article content if it appears as the first heading
    if sections[:article] && sections[:title]
      # Check for HTML title format
      html_title = "<h1>#{sections[:title]}</h1>"

      if sections[:article].start_with?(html_title)
        sections[:article] = sections[:article].sub(html_title, "").strip
      end
    end

    sections
  end

      def generate_article_image(topic, keyword, style)
    image_prompt = build_image_prompt(topic, keyword, style)
    Rails.logger.info "Starting image generation for topic: #{topic}"
    Rails.logger.info "Image prompt: #{image_prompt}"

    begin
      response = @client.images.generate(
        parameters: {
          model: "dall-e-3",
          prompt: image_prompt,
          size: "1024x1024",
          quality: "standard",
          n: 1
        }
      )

      image_url = response.dig("data", 0, "url")
      Rails.logger.info "Generated image for article: #{topic} - URL: #{image_url}"
      image_url
    rescue => e
      Rails.logger.error "DALL-E Image Generation Error: #{e.message}"
      Rails.logger.error "Image prompt was: #{image_prompt}"
      nil
    end
  end

  def build_image_prompt(topic, keyword, style)
    base_prompt = "Professional, modern illustration for a blog article about '#{topic}'"

    style_specific = case style.to_sym
    when :listicle
      "infographic style with clean icons and numbered elements"
    when :how_to
      "step-by-step visual guide with clear progression"
    when :comparison
      "side-by-side comparison layout with balanced elements"
    else
      "clean business illustration with email marketing elements"
    end

    prompt = "#{base_prompt}, #{style_specific}. "
    prompt += "Focus on #{keyword} concept. "
    prompt += "Use professional blue and white color scheme, flat design, "
    prompt += "suitable for business blog header, no text overlay, "
    prompt += "high quality, digital art style, corporate aesthetic"

    # Ensure prompt is under DALL-E's limit
    prompt.truncate(1000)
  end

  def attach_image_from_url(article, image_url)
    begin
      # Download the image
      uri = URI.parse(image_url)
      image_data = Net::HTTP.get(uri)

      # Create a temporary file
      temp_file = Tempfile.new([ "article_image", ".png" ])
      temp_file.binmode
      temp_file.write(image_data)
      temp_file.rewind

      # Attach to article
      article.cover_image.attach(
        io: temp_file,
        filename: "article_#{article.id}_cover.png",
        content_type: "image/png"
      )

      Rails.logger.info "Successfully attached image to article: #{article.title}"
    rescue => e
      Rails.logger.error "Error attaching image: #{e.message}"
    ensure
      temp_file&.close
      temp_file&.unlink
    end
  end
end
