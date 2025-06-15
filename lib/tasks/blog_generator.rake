namespace :blog do
  desc "Generate a blog article with interactive prompts"
  task generate: :environment do
    puts "🚀 Interactive Blog Article Generator"
    puts "=" * 50

    # Check OpenAI credentials first
    begin
      api_key = Rails.application.credentials.openai.api_key
      unless api_key.present?
        puts "❌ OpenAI API key is missing from credentials"
        puts "   Please configure your OpenAI API key in Rails credentials"
        exit 1
      end
    rescue => e
      puts "❌ Error accessing OpenAI credentials: #{e.message}"
      exit 1
    end

    # Prompt for topic
    print "\n📝 Enter the blog topic: "
    topic = STDIN.gets.chomp.strip
    if topic.blank?
      puts "❌ Topic cannot be empty"
      exit 1
    end

    # Prompt for keyword
    print "\n🔍 Enter the primary keyword: "
    keyword = STDIN.gets.chomp.strip
    if keyword.blank?
      puts "❌ Keyword cannot be empty"
      exit 1
    end

    # Prompt for audience
    print "\n👥 Enter the target audience: "
    audience = STDIN.gets.chomp.strip
    if audience.blank?
      puts "❌ Audience cannot be empty"
      exit 1
    end

    # Prompt for style
    puts "\n🎨 Select article style:"
    puts "   1. Standard (default)"
    puts "   2. Listicle"
    puts "   3. How-to Guide"
    puts "   4. Comparison"
    print "Enter choice (1-4) [1]: "

    style_choice = STDIN.gets.chomp.strip
    style_choice = "1" if style_choice.blank?

    style_map = {
      "1" => :standard,
      "2" => :listicle,
      "3" => :how_to,
      "4" => :comparison
    }

    style = style_map[style_choice] || :standard
    style_name = style.to_s.humanize

    # Confirm details
    puts "\n📋 Article Details:"
    puts "   Topic: #{topic}"
    puts "   Keyword: #{keyword}"
    puts "   Audience: #{audience}"
    puts "   Style: #{style_name}"

    print "\n✅ Generate article with these details? (y/N): "
    confirmation = STDIN.gets.chomp.strip.downcase

    unless confirmation == "y" || confirmation == "yes"
      puts "❌ Article generation cancelled"
      exit 0
    end

    # Generate the article
    puts "\n🤖 Generating article (this may take 30-60 seconds)..."
    puts "   Please wait..."

    begin
      generator = BlogGenerator.new
      result = generator.generate_blog_post(
        topic: topic,
        keyword: keyword,
        audience: audience,
        style: style
      )

      if result && result[:title] && result[:article]
        # Create the article
        article = Article.create!(
          title: result[:title],
          content: result[:article],
          keywords: keyword,
          meta_description: result[:meta_description] || "#{topic} - #{keyword}"
        )

        # Attach generated image if available
        if result[:image_url]
          puts "   🖼️  Attaching generated image..."
          generator.send(:attach_image_from_url, article, result[:image_url])
        end

        puts "\n🎉 Article generated successfully!"
        puts "   ID: #{article.id}"
        puts "   Title: #{article.title}"
        puts "   Slug: #{article.slug}"
        puts "   Content length: #{article.content.length} characters"
        puts "   Word count: #{article.word_count} words"
        puts "   Reading time: #{article.reading_time} minutes"
        puts "   URL: /articles/#{article.slug}"
        puts "   Cover image: #{article.cover_image.attached? ? '✅ Attached' : '❌ Not attached'}"

        if result[:model_used]
          puts "   Model used: #{result[:model_used]}"
        end

        if result[:tokens_used]
          puts "   Tokens used: #{result[:tokens_used]}"
        end
      else
        puts "❌ Failed to generate article - invalid response from AI"
        exit 1
      end
    rescue => e
      puts "❌ Error generating article: #{e.message}"
      puts "   #{e.backtrace.first(3).join("\n   ")}"
      exit 1
    end
  end

  desc "Test OpenAI integration by generating a sample blog post"
  task test_integration: :environment do
    puts "🚀 Testing OpenAI Blog Generation Integration..."
    puts "=" * 50

    # Test 1: Check if OpenAI credentials are configured
    puts "\n1. Checking OpenAI credentials..."
    begin
      api_key = Rails.application.credentials.openai.api_key
      if api_key.present?
        puts "✅ OpenAI API key is configured"
      else
        puts "❌ OpenAI API key is missing from credentials"
        exit 1
      end
    rescue => e
      puts "❌ Error accessing OpenAI credentials: #{e.message}"
      exit 1
    end

    # Test 2: Initialize BlogGenerator
    puts "\n2. Initializing BlogGenerator..."
    begin
      generator = BlogGenerator.new
      puts "✅ BlogGenerator initialized successfully"
    rescue => e
      puts "❌ Error initializing BlogGenerator: #{e.message}"
      exit 1
    end

    # Test 3: Generate a test article
    puts "\n3. Generating test article..."
    begin
      test_topic = "Email Marketing Best Practices for Small Businesses"
      test_keyword = "email marketing tips"
      test_audience = "small business owners"

      puts "   Test topic: #{test_topic}"
      puts "   Test keyword: #{test_keyword}"
      puts "   Test audience: #{test_audience}"

      puts "\n   🤖 Calling OpenAI API (this may take 30-60 seconds)..."
      result = generator.generate_blog_post(
        topic: test_topic,
        keyword: test_keyword,
        audience: test_audience
      )

      if result
        puts "✅ Article generated successfully!"
        puts "   Title: #{result[:title]}"
        puts "   Meta Description: #{result[:meta_description]}"
        puts "   Content length: #{result[:article]&.length || 0} characters"
        puts "   Model used: #{result[:model_used]}"
        puts "   Tokens used: #{result[:tokens_used]}"
      else
        puts "❌ Failed to generate article"
        exit 1
      end
    rescue => e
      puts "❌ Error generating article: #{e.message}"
      puts "   #{e.backtrace.first(3).join("\n   ")}"
      exit 1
    end

    puts "\n🎉 All tests passed! OpenAI integration is working correctly."
    puts "=" * 50
  end
end
