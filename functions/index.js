const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const { Pinecone } = require('@pinecone-database/pinecone');
const OpenAI = require('openai');
const pdfParse = require('pdf-parse');
const { encoding_for_model } = require('tiktoken');
const natural = require('natural');
const Busboy = require('busboy');

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// Initialize Express app
const app = express();
app.use(cors({ origin: true }));
app.use(express.json({ limit: '50mb' }));

// Initialize OpenAI and Pinecone clients
let openai, pinecone, pineconeIndex;
let servicesInitialized = false;
let initializationPromise = null;

const initializeServices = async () => {
  if (servicesInitialized) {
    return true;
  }
  
  if (initializationPromise) {
    return initializationPromise;
  }
  
  initializationPromise = (async () => {
    try {
      console.log('🚀 Starting RAG services initialization...');
      
      // Get API keys from environment variables or config
      const openaiKey = functions.config().openai?.key || process.env.OPENAI_API_KEY;
      const pineconeKey = functions.config().pinecone?.key || process.env.PINECONE_API_KEY;
      
      // For local development, we can skip initialization if no keys are provided
      if (!openaiKey || !pineconeKey) {
        console.log('⚠️ API keys not found, running in mock mode for local development');
        servicesInitialized = true;
        return true;
      }
      
      // Initialize OpenAI
      openai = new OpenAI({ apiKey: openaiKey });
      console.log('✅ OpenAI initialized');
      
      // Initialize Pinecone with proper configuration for v2
      pinecone = new Pinecone({
        apiKey: pineconeKey
      });
      console.log('✅ Pinecone client initialized');
      
      // Get or create index
      const indexName = 'nctb-textbooks';
      try {
        // Try to connect to existing index directly
        pineconeIndex = pinecone.index(indexName);
        console.log('✅ Connected to existing Pinecone index:', indexName);
      } catch (indexError) {
        console.log('❌ Failed to connect to index:', indexError.message);
        // Don't throw error for local development
        console.log('⚠️ Running without Pinecone for local development');
      }
      
      servicesInitialized = true;
      console.log('✅ RAG services initialized successfully');
      return true;
    } catch (error) {
      console.error('❌ Failed to initialize RAG services:', error);
      // For local development, don't fail completely
      console.log('⚠️ Running in degraded mode for local development');
      servicesInitialized = true;
      initializationPromise = null;
      return true;
    }
  })();
  
  return initializationPromise;
};

// Middleware to ensure services are initialized
const ensureServicesInitialized = async (req, res, next) => {
  try {
    await initializeServices();
    next();
  } catch (error) {
    console.error('Service initialization failed, but continuing for local development:', error);
    // For local development, continue even if services aren't fully initialized
    next();
  }
};

// NCTB Curriculum Structure
const CURRICULUM = {
  '9': {
    'Physics': ['Motion', 'Force and Pressure', 'Work, Power and Energy', 'Sound', 'Light'],
    'Chemistry': ['Matter and Its States', 'Elements and Compounds', 'Acids, Bases and Salts', 'Chemical Reactions'],
    'Biology': ['Cell and Its Structure', 'Life Process', 'Reproduction', 'Heredity and Evolution'],
    'Mathematics': ['Real Numbers', 'Sets and Functions', 'Algebraic Expressions', 'Indices and Logarithms', 'Linear Equations']
  },
  '10': {
    'Physics': ['Heat and Temperature', 'Waves and Sound', 'Light and Optics', 'Electricity and Magnetism', 'Modern Physics'],
    'Chemistry': ['Atomic Structure', 'Periodic Table', 'Chemical Bonding', 'Metals and Non-metals', 'Organic Chemistry'],
    'Biology': ['Nutrition', 'Respiration', 'Transportation', 'Excretion', 'Control and Coordination'],
    'Mathematics': ['Trigonometry', 'Geometry', 'Coordinate Geometry', 'Statistics', 'Probability']
  },
  '11': {
    'Physics': ['Mechanics', 'Thermal Physics', 'Waves', 'Electricity', 'Magnetism'],
    'Chemistry': ['General Chemistry', 'Organic Chemistry', 'Physical Chemistry', 'Inorganic Chemistry'],
    'Biology': ['Cell Biology', 'Plant Biology', 'Animal Biology', 'Human Biology', 'Ecology'],
    'Mathematics': ['Calculus', 'Algebra', 'Geometry', 'Trigonometry', 'Statistics']
  },
  '12': {
    'Physics': ['Advanced Mechanics', 'Thermodynamics', 'Electromagnetic Waves', 'Modern Physics', 'Electronics'],
    'Chemistry': ['Advanced Organic Chemistry', 'Physical Chemistry', 'Inorganic Chemistry', 'Environmental Chemistry'],
    'Biology': ['Advanced Cell Biology', 'Genetics', 'Evolution', 'Biotechnology', 'Environmental Biology'],
    'Mathematics': ['Advanced Calculus', 'Linear Algebra', 'Differential Equations', 'Probability', 'Statistics']
  }
};

// Utility functions
const chunkText = (text, maxTokens = 500, overlapTokens = 50) => {
  const encoder = encoding_for_model('text-embedding-3-large');
  const sentences = text.split(/[.!?]+/).filter(s => s.trim().length > 0);
  const chunks = [];
  let currentChunk = '';
  let currentTokens = 0;
  
  for (const sentence of sentences) {
    const sentenceTokens = encoder.encode(sentence.trim()).length;
    
    if (currentTokens + sentenceTokens > maxTokens && currentChunk) {
      chunks.push(currentChunk.trim());
      // Start new chunk with overlap
      const words = currentChunk.split(' ');
      const overlapWords = words.slice(-Math.floor(overlapTokens / 2));
      currentChunk = overlapWords.join(' ') + ' ' + sentence.trim();
      currentTokens = encoder.encode(currentChunk).length;
    } else {
      currentChunk += (currentChunk ? ' ' : '') + sentence.trim();
      currentTokens += sentenceTokens;
    }
  }
  
  if (currentChunk.trim()) {
    chunks.push(currentChunk.trim());
  }
  
  encoder.free();
  return chunks;
};

const generateEmbedding = async (text) => {
  try {
    const response = await openai.embeddings.create({
      model: 'text-embedding-3-large',
      input: text,
      encoding_format: 'float'
    });
    return response.data[0].embedding;
  } catch (error) {
    console.error('Error generating embedding:', error);
    throw error;
  }
};

const detectChapterFromText = (text, subject) => {
  const chapters = CURRICULUM['9'][subject] || [];
  for (const chapter of chapters) {
    if (text.toLowerCase().includes(chapter.toLowerCase())) {
      return chapter;
    }
  }
  // Use first 100 words as fallback
  return text.split(' ').slice(0, 15).join(' ') + '...';
};

// Apply middleware to routes that need RAG services
app.use('/upload-textbook', ensureServicesInitialized);
app.use('/ask-question', ensureServicesInitialized);
app.use('/search-content', ensureServicesInitialized);
app.use('/generate-summary', ensureServicesInitialized);
app.use('/generate-quiz', ensureServicesInitialized);

// API Routes

// Health check
app.get('/', async (req, res) => {
  res.json({
    status: 'healthy',
    service: 'NCTB RAG API (Cloud Functions)',
    version: '1.0.0',
    rag_initialized: servicesInitialized && openai && pinecone && pineconeIndex,
    timestamp: new Date().toISOString()
  });
});

// Configure multer for memory storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB limit
  },
});

// Upload textbook
app.post('/upload-textbook', upload.single('file'), async (req, res) => {
  console.log('📁 Upload textbook endpoint called');
  console.log('📁 Headers:', req.headers);
  console.log('📁 Body fields:', req.body);
  console.log('� File info:', req.file ? {
    fieldname: req.file.fieldname,
    originalname: req.file.originalname,
    mimetype: req.file.mimetype,
    size: req.file.size
  } : 'No file');

  try {
    const { class_level, subject, chapter_name } = req.body;
    
    console.log('📝 Form data received:');
    console.log('   Class level:', class_level);
    console.log('   Subject:', subject);
    console.log('   Chapter name:', chapter_name);
    
    if (!class_level || !subject) {
      console.log('❌ Missing required fields');
      return res.status(400).json({ error: 'class_level and subject are required' });
    }
    
    if (!req.file || !req.file.buffer) {
      console.log('❌ No file or empty file buffer');
      return res.status(400).json({ error: 'No file uploaded or file is empty' });
    }
    
    console.log('📊 File details:');
    console.log('   Size:', req.file.buffer.length, 'bytes');
    console.log('   MIME type:', req.file.mimetype);
    console.log('   Original name:', req.file.originalname);
    
    if (!openai || !pineconeIndex) {
      console.log('❌ RAG services not initialized');
      return res.status(500).json({ error: 'RAG services not initialized' });
    }
    
    console.log('📖 Parsing PDF...');
    // Parse PDF
    const pdfData = await pdfParse(req.file.buffer);
    const text = pdfData.text;
    
    if (!text || text.length < 100) {
      console.log('❌ PDF empty or unreadable');
      return res.status(400).json({ error: 'PDF appears to be empty or unreadable' });
    }
    
    console.log(`📖 PDF parsed successfully: ${text.length} characters`);
    
    // Auto-detect chapter if not provided
    const detectedChapter = chapter_name || detectChapterFromText(text, subject);
    console.log(`📚 Chapter: ${detectedChapter}`);
    
    // Chunk the text
    const chunks = chunkText(text);
    const processedChunks = [];
    
    console.log(`🔪 Created ${chunks.length} chunks`);
    
    // Process each chunk
    for (let i = 0; i < chunks.length; i++) {
      const chunk = chunks[i];
      const chunkId = `${class_level}_${subject}_${detectedChapter}_${i + 1}`.replace(/[^a-zA-Z0-9_]/g, '_');
      
      // Generate embedding
      const embedding = await generateEmbedding(chunk);
      
      // Prepare chunk metadata
      const chunkData = {
        chunk_id: chunkId,
        text: chunk,
        class_level: class_level,
        subject: subject,
        chapter: detectedChapter,
        page_number: Math.floor(i / 10) + 1,
        word_count: chunk.split(' ').length,
        created_at: admin.firestore.FieldValue.serverTimestamp()
      };
      
      // Store in Pinecone
      await pineconeIndex.upsert([{
        id: chunkId,
        values: embedding,
        metadata: {
          class_level,
          subject,
          chapter: detectedChapter,
          page_number: chunkData.page_number,
          word_count: chunkData.word_count
        }
      }]);
      
      // Store in Firestore
      await db.collection('textbook_chunks').doc(chunkId).set(chunkData);
      
      processedChunks.push(chunkData);
    }
    
    console.log('✅ All chunks processed successfully');
    
    res.json({
      status: 'success',
      message: `Processed ${chunks.length} chunks from ${subject} Class ${class_level}`,
      chunks_count: chunks.length,
      pinecone_stored: true,
      firestore_stored: true,
      class_level,
      subject,
      chapter_name: detectedChapter
    });
    
  } catch (error) {
    console.error('❌ Upload processing error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Ask question
app.post('/ask-question', async (req, res) => {
  try {
    const { question, class_level, subject, chapter } = req.body;
    
    if (!question || !class_level) {
      return res.status(400).json({ error: 'question and class_level are required' });
    }
    
    if (!openai || !pineconeIndex) {
      return res.status(500).json({ error: 'RAG services not initialized' });
    }
    
    // Generate embedding for question
    const questionEmbedding = await generateEmbedding(question);
    
    // Build filter for Pinecone search
    const filter = { class_level: { $eq: class_level } };
    if (subject) filter.subject = { $eq: subject };
    if (chapter) filter.chapter = { $eq: chapter };
    
    // Search in Pinecone
    const searchResults = await pineconeIndex.query({
      vector: questionEmbedding,
      filter,
      topK: 5,
      includeMetadata: true
    });
    
    // Get chunk details from Firestore
    const sourceChunks = [];
    for (const match of searchResults.matches) {
      const chunkDoc = await db.collection('textbook_chunks').doc(match.id).get();
      if (chunkDoc.exists) {
        const chunkData = chunkDoc.data();
        sourceChunks.push({
          chunk_id: match.id,
          score: match.score,
          text: chunkData.text,
          class_level: chunkData.class_level,
          subject: chunkData.subject,
          chapter: chunkData.chapter,
          page_number: chunkData.page_number,
          word_count: chunkData.word_count
        });
      }
    }
    
    // Generate context from relevant chunks
    const context = sourceChunks.map(chunk => chunk.text).join('\n\n');
    
    // Generate RAG response
    const prompt = `You are an expert NCTB (Bangladesh) tutor for Class ${class_level}${subject ? ` ${subject}` : ''}${chapter ? ` - ${chapter}` : ''}.

Context from textbook:
${context}

Student question: ${question}

Provide a comprehensive answer based on the textbook content. If the question cannot be answered from the provided context, say so clearly.`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        { role: 'system', content: 'You are an expert NCTB tutor helping students understand their textbooks.' },
        { role: 'user', content: prompt }
      ],
      max_tokens: 1000,
      temperature: 0.7
    });
    
    const answer = completion.choices[0].message.content;
    const confidence = sourceChunks.length > 0 ? Math.min(sourceChunks[0].score * 100, 95) : 50;
    
    res.json({
      status: 'success',
      answer,
      confidence,
      source_chunks_count: sourceChunks.length,
      sources: sourceChunks,
      query: question,
      class_level,
      subject,
      chapter
    });
    
  } catch (error) {
    console.error('Question answering error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Search content
app.post('/search-content', async (req, res) => {
  try {
    const { query, class_level, subject, chapter, top_k = 5 } = req.body;
    
    if (!query || !class_level) {
      return res.status(400).json({ error: 'query and class_level are required' });
    }
    
    if (!openai || !pineconeIndex) {
      return res.status(500).json({ error: 'RAG services not initialized' });
    }
    
    // Generate embedding for query
    const queryEmbedding = await generateEmbedding(query);
    
    // Build filter
    const filter = { class_level: { $eq: class_level } };
    if (subject) filter.subject = { $eq: subject };
    if (chapter) filter.chapter = { $eq: chapter };
    
    // Search in Pinecone
    const searchResults = await pineconeIndex.query({
      vector: queryEmbedding,
      filter,
      topK: parseInt(top_k),
      includeMetadata: true
    });
    
    // Get chunk details
    const chunks = [];
    for (const match of searchResults.matches) {
      const chunkDoc = await db.collection('textbook_chunks').doc(match.id).get();
      if (chunkDoc.exists) {
        const chunkData = chunkDoc.data();
        chunks.push({
          chunk_id: match.id,
          score: match.score,
          text: chunkData.text,
          class_level: chunkData.class_level,
          subject: chunkData.subject,
          chapter: chunkData.chapter,
          page_number: chunkData.page_number,
          word_count: chunkData.word_count
        });
      }
    }
    
    res.json({
      status: 'success',
      chunks,
      total_found: chunks.length,
      query,
      class_level,
      subject,
      chapter
    });
    
  } catch (error) {
    console.error('Search error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Generate summary
app.post('/generate-summary', async (req, res) => {
  try {
    const { class_level, subject, chapter } = req.body;
    
    if (!class_level || !subject || !chapter) {
      return res.status(400).json({ error: 'class_level, subject, and chapter are required' });
    }
    
    // Use chapter name as search query
    const queryEmbedding = await generateEmbedding(chapter);
    
    // Search for chapter content
    const searchResults = await pineconeIndex.query({
      vector: queryEmbedding,
      filter: {
        class_level: { $eq: class_level },
        subject: { $eq: subject },
        chapter: { $eq: chapter }
      },
      topK: 20,
      includeMetadata: true
    });
    
    // Get chunks
    const chunks = [];
    for (const match of searchResults.matches) {
      const chunkDoc = await db.collection('textbook_chunks').doc(match.id).get();
      if (chunkDoc.exists) {
        chunks.push(chunkDoc.data().text);
      }
    }
    
    if (chunks.length === 0) {
      return res.status(400).json({ error: 'No content found for this chapter' });
    }
    
    const content = chunks.join('\n\n');
    
    const summaryPrompt = `Summarize the following chapter content from Class ${class_level} ${subject} textbook.

Chapter: ${chapter}

Content:
${content}

Provide a comprehensive summary that includes:
1. Key concepts and definitions
2. Important formulas or principles
3. Main topics covered
4. Real-world applications mentioned

Keep the summary clear and suitable for Class ${class_level} students.`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        { role: 'system', content: 'You are an expert teacher creating chapter summaries for NCTB textbooks.' },
        { role: 'user', content: summaryPrompt }
      ],
      max_tokens: 1000,
      temperature: 0.7
    });
    
    res.json({
      status: 'success',
      summary: completion.choices[0].message.content,
      chapter,
      class_level,
      subject,
      source_chunks: chunks.length
    });
    
  } catch (error) {
    console.error('Summary generation error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Generate quiz
app.post('/generate-quiz', async (req, res) => {
  try {
    const { class_level, subject, chapter, mcq_count = 5, short_count = 2 } = req.body;
    
    if (!class_level || !subject || !chapter) {
      return res.status(400).json({ error: 'class_level, subject, and chapter are required' });
    }
    
    // Similar to summary generation but for quiz
    const queryEmbedding = await generateEmbedding(chapter);
    
    const searchResults = await pineconeIndex.query({
      vector: queryEmbedding,
      filter: {
        class_level: { $eq: class_level },
        subject: { $eq: subject },
        chapter: { $eq: chapter }
      },
      topK: 15,
      includeMetadata: true
    });
    
    const chunks = [];
    for (const match of searchResults.matches) {
      const chunkDoc = await db.collection('textbook_chunks').doc(match.id).get();
      if (chunkDoc.exists) {
        chunks.push(chunkDoc.data().text);
      }
    }
    
    if (chunks.length === 0) {
      return res.status(400).json({ error: 'No content found for this chapter' });
    }
    
    const content = chunks.join('\n\n');
    
    const quizPrompt = `Create a quiz for Class ${class_level} ${subject} students based on the following chapter content.

Chapter: ${chapter}

Content:
${content}

Generate:
1. ${mcq_count} multiple choice questions (MCQs) with 4 options each
2. ${short_count} short answer questions

Format the response as a JSON object with the following structure:
{
    "mcqs": [
        {
            "question": "Question text",
            "options": ["A) Option 1", "B) Option 2", "C) Option 3", "D) Option 4"],
            "correct_answer": "A",
            "explanation": "Why this is correct"
        }
    ],
    "short_questions": [
        {
            "question": "Question text",
            "sample_answer": "Sample answer"
        }
    ]
}

Make sure questions are appropriate for Class ${class_level} level and based on the provided content.`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        { role: 'system', content: 'You are an expert teacher creating quizzes for NCTB textbooks. Always respond with valid JSON.' },
        { role: 'user', content: quizPrompt }
      ],
      max_tokens: 2000,
      temperature: 0.7
    });
    
    let quizData;
    try {
      quizData = JSON.parse(completion.choices[0].message.content);
    } catch (parseError) {
      quizData = {
        mcqs: [],
        short_questions: [],
        raw_content: completion.choices[0].message.content
      };
    }
    
    res.json({
      status: 'success',
      quiz: quizData,
      chapter,
      class_level,
      subject,
      source_chunks: chunks.length
    });
    
  } catch (error) {
    console.error('Quiz generation error:', error);
    res.status(500).json({ error: error.message });
  }
});

// List subjects
app.get('/list-subjects', async (req, res) => {
  res.json({
    status: 'success',
    curriculum: CURRICULUM
  });
});

// Export the Cloud Function
exports.ragApi = functions
  .region('us-central1')
  .runWith({
    timeoutSeconds: 540,
    memory: '2GB'
  })
  .https
  .onRequest(app);
